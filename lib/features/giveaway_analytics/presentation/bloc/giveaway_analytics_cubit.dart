import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/result.dart';
import '../../../../shared/models/eligible_participant.dart';
import '../../../../shared/repositories/giveaway_repository.dart';
import '../../../../shared/repositories/storage_repository.dart';
import '../../../../shared/repositories/winner_repository.dart';
import 'giveaway_analytics_state.dart';

/// Correctness-first (no cache) -- an admin picking a winner needs to see
/// the true current participant count, not a stale cached one.
class GiveawayAnalyticsCubit extends Cubit<GiveawayAnalyticsState> {
  GiveawayAnalyticsCubit(
    this._giveawayRepository,
    this._winnerRepository,
    this._client,
    this._storageRepository,
  ) : super(const GiveawayAnalyticsState());

  final GiveawayRepository _giveawayRepository;
  final WinnerRepository _winnerRepository;
  final SupabaseClient _client;
  final StorageRepository _storageRepository;
  RealtimeChannel? _channel;
  Timer? _reloadDebounce;

  Future<void> load(String giveawayId) async {
    emit(state.copyWith(status: GiveawayAnalyticsStatus.loading));

    final giveawayResult = await _giveawayRepository.getGiveawayById(
      giveawayId,
      forceRefresh: true,
    );

    await giveawayResult.fold(
      (failure) async =>
          emit(state.copyWith(status: GiveawayAnalyticsStatus.error, failure: failure)),
      (giveaway) async {
        try {
          final participantRows = await _client
              .from('participations')
              .select(
                'participation_sequence, participation_number, created_at, users(full_name, phone_e164)',
              )
              .eq('giveaway_id', giveawayId)
              .order('created_at', ascending: false);

          final allRows = List<Map<String, dynamic>>.from(participantRows as List);

          final recent = allRows
              .take(20)
              .map(
                (row) => RecentParticipant(
                  participationSequence: row['participation_sequence'] as int,
                  participationNumber: row['participation_number'] as int? ?? 0,
                  fullName: (row['users'] as Map?)?['full_name'] as String? ?? 'Anonymous',
                  phoneE164: (row['users'] as Map?)?['phone_e164'] as String?,
                  createdAt: DateTime.parse(row['created_at'] as String),
                ),
              )
              .toList();

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final dailyGrowth = List<int>.filled(7, 0);
          var activeToday = 0;

          for (final row in allRows) {
            final createdAt = DateTime.parse(row['created_at'] as String).toLocal();
            final daysAgo = today
                .difference(DateTime(createdAt.year, createdAt.month, createdAt.day))
                .inDays;
            if (daysAgo >= 0 && daysAgo < 7) {
              dailyGrowth[6 - daysAgo]++;
            }
            if (now.difference(createdAt).inHours < 24) {
              activeToday++;
            }
          }

          final winnersResult = await _winnerRepository.getWinnersForGiveaway(giveawayId);

          emit(
            state.copyWith(
              status: GiveawayAnalyticsStatus.loaded,
              giveaway: giveaway,
              recentParticipants: recent,
              dailyGrowth: dailyGrowth,
              activeToday: activeToday,
              winners: winnersResult.fold((_) => const [], (w) => w),
            ),
          );
        } catch (_) {
          emit(state.copyWith(status: GiveawayAnalyticsStatus.loaded, giveaway: giveaway));
        }
      },
    );
  }

  /// The candidate list for the manual "Select Winner" participant picker --
  /// a thin passthrough so the UI never talks to [WinnerRepository] directly
  /// (keeps the existing UI -> Cubit -> Repository layering for this page).
  Future<Result<List<EligibleParticipant>>> fetchEligibleParticipants(String giveawayId) {
    return _winnerRepository.getEligibleParticipants(giveawayId);
  }

  /// Marks [participant] as the pending manual target for the *next*
  /// "Select Winner"/"Select Another Winner" press -- this alone never
  /// selects a winner. Picking a different participant (the admin changing
  /// their mind) simply overwrites the previous pending target.
  void setManualTarget(EligibleParticipant participant) {
    emit(state.copyWith(manualTarget: participant));
  }

  /// Clears the pending manual target -- "Select Winner" reverts to the
  /// normal random behavior.
  void clearManualTarget() {
    emit(state.copyWith(clearManualTarget: true));
  }

  /// Selects (another) winner. [participationId] omitted/null means the
  /// server picks uniformly at random among eligible participants
  /// (`fn_select_winner`'s own `order by random() ... skip locked`) --
  /// provided means the admin's explicit manual choice. Either way this is
  /// the SAME server-authoritative call; nothing about winner persistence,
  /// duplicate-winner protection, giveaway-status transition, or
  /// notification dispatch changes based on which path picked the target.
  /// Multiple winners are fully supported -- each call picks the next rank
  /// (state.winners.length + 1), so admins can keep calling this until
  /// there are no eligible participants left (surfaced as a
  /// [ValidationFailure]/`no_eligible_participants`).
  ///
  /// Returns `true` only once the server has confirmed the winner was
  /// actually persisted -- callers (the wheel/celebration trigger) must
  /// never fire on anything else, per the "animate only after server
  /// confirmation" requirement. On success, [lastSelectedWinner] is set to
  /// the exact winner returned (available immediately, without waiting on
  /// the fire-and-forget [load] reload below), and any pending manual
  /// target is cleared -- consumed either way, whether it was actually used
  /// or this was a random pick.
  Future<bool> selectWinner(String giveawayId, {String? participationId}) async {
    emit(state.copyWith(isSelectingWinner: true));
    final result = await _winnerRepository.selectWinner(
      giveawayId: giveawayId,
      participationId: participationId,
      rank: state.winners.length + 1,
    );
    emit(state.copyWith(isSelectingWinner: false));
    return result.fold(
      (failure) {
        emit(state.copyWith(failure: failure));
        return false;
      },
      (winner) {
        emit(state.copyWith(lastSelectedWinner: winner, clearManualTarget: true));
        load(giveawayId);
        return true;
      },
    );
  }

  /// Live "participant joined" / "winner selected" updates while this page
  /// is open, so an admin doesn't have to pull-to-refresh to see them. Scoped
  /// to exactly this one giveaway (never a blanket subscription to every
  /// participation/winner in the app) and only INSERTs, since those are the
  /// only events that change what this screen shows. Call once per page
  /// instance (e.g. from the page's `initState`) -- a second call while
  /// already subscribed is a safe no-op, and [close] tears the channel down.
  ///
  /// Bursts (several participants joining within milliseconds of each other)
  /// are coalesced into a single reload via a short debounce rather than
  /// re-querying once per event.
  void subscribeToRealtime(String giveawayId) {
    if (_channel != null) return;
    _channel = _client
        .channel('giveaway-analytics-$giveawayId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'participations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'giveaway_id',
            value: giveawayId,
          ),
          callback: (_) => _scheduleReload(giveawayId),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'winners',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'giveaway_id',
            value: giveawayId,
          ),
          callback: (_) => _scheduleReload(giveawayId),
        )
        .subscribe();
  }

  void _scheduleReload(String giveawayId) {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!isClosed) load(giveawayId);
    });
  }

  /// Admin-only TRUE hard delete: removes the giveaway and every DB record
  /// that belongs exclusively to it (participations, winners, and other
  /// giveaway-scoped rows) via [GiveawayRepository.deleteGiveaway]'s atomic,
  /// server-authorized RPC -- the caller who joined a deleted giveaway keeps
  /// their global account untouched. On success, the giveaway's uploaded
  /// image (if any) is best-effort removed from Storage afterward; a
  /// failure there never affects the return value, since the database
  /// records (the source of truth for "was this giveaway deleted") are
  /// already gone by that point.
  ///
  /// Returns `true` only once the server has confirmed the delete. Callers
  /// (the confirmation dialog) should navigate away on `true` -- other
  /// admin screens (Admin Dashboard) pick up the removal on their own via
  /// their existing Realtime subscription to `giveaways`, the same as any
  /// other giveaway change.
  Future<bool> deleteGiveaway(String giveawayId) async {
    final imageUrl = state.giveaway?.imageUrl;
    final result = await _giveawayRepository.deleteGiveaway(giveawayId);
    return result.fold(
      (failure) {
        emit(state.copyWith(failure: failure));
        return false;
      },
      (_) {
        unawaited(_storageRepository.deleteGiveawayImage(imageUrl));
        return true;
      },
    );
  }

  @override
  Future<void> close() {
    _reloadDebounce?.cancel();
    final channel = _channel;
    _channel = null;
    if (channel != null) _client.removeChannel(channel);
    return super.close();
  }
}
