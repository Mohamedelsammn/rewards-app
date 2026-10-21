import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/models/giveaway.dart';
import '../../../../shared/models/giveaway_requirement.dart';
import '../../../../shared/repositories/giveaway_repository.dart';
import '../../../../shared/repositories/participation_repository.dart';
import 'giveaway_details_state.dart';

class GiveawayDetailsCubit extends Cubit<GiveawayDetailsState> {
  /// [seed], when provided, is the giveaway data the caller already had in
  /// hand (e.g. tapping a card on Home/My Giveaways) -- it seeds the very
  /// first frame as already-loaded, so navigating in never shows a loading
  /// screen. [load] still runs to silently refresh it and fetch
  /// requirements/participation status.
  GiveawayDetailsCubit(
    this._giveawayRepository,
    this._participationRepository,
    this._client, {
    Giveaway? seed,
  }) : super(
         seed == null
             ? const GiveawayDetailsState()
             : GiveawayDetailsState(
                 status: GiveawayDetailsStatus.loaded,
                 giveaway: seed,
                 participationCheckStatus: ParticipationCheckStatus.loading,
               ),
       ) {
    if (seed != null) _armStatusBoundary(seed);
  }

  final GiveawayRepository _giveawayRepository;
  final ParticipationRepository _participationRepository;
  final SupabaseClient _client;
  RealtimeChannel? _channel;
  Timer? _reloadDebounce;
  Timer? _statusBoundary;
  int _loadGeneration = 0;
  void _armStatusBoundary(Giveaway giveaway) {
    _statusBoundary?.cancel();
    final now = DateTime.now();
    final next = now.isBefore(giveaway.startsAt) ? giveaway.startsAt : giveaway.endsAt;
    if (!next.isAfter(now)) return;
    _statusBoundary = Timer(next.difference(now) + const Duration(milliseconds: 50), () {
      if (isClosed) return;
      emit(state.copyWith(clockRevision: state.clockRevision + 1));
      _armStatusBoundary(giveaway);
    });
  }

  Future<void> load(String giveawayId, {bool forceRefresh = false}) async {
    final generation = ++_loadGeneration;
    // Cache-first, same no-flash policy as UserHomeCubit.load: nothing to
    // show yet (no seed from the caller) -- try a synchronous cache-only
    // peek before ever falling back to a blocking spinner.
    if (!forceRefresh && state.giveaway == null) {
      final cached = _giveawayRepository.peekCachedGiveaway(giveawayId);
      if (cached != null) {
        emit(state.copyWith(status: GiveawayDetailsStatus.loaded, giveaway: cached));
        _armStatusBoundary(cached);
      }
    }
    if (state.giveaway == null) {
      emit(state.copyWith(status: GiveawayDetailsStatus.loading));
    }

    final giveawayResult = await _giveawayRepository.getGiveawayById(
      giveawayId,
      forceRefresh: forceRefresh,
    );
    if (isClosed || generation != _loadGeneration) return;

    await giveawayResult.fold(
      (failure) async {
        // A background-refresh failure shouldn't blank out a seeded/cached
        // giveaway already on screen -- only surface the error state when
        // there's genuinely nothing to show.
        if (state.giveaway == null) {
          emit(state.copyWith(status: GiveawayDetailsStatus.error, failure: failure));
        } else {
          emit(state.copyWith(participationCheckStatus: ParticipationCheckStatus.error));
        }
      },
      (giveaway) async {
        _armStatusBoundary(giveaway);
        final requirementsResult = await _giveawayRepository.getRequirements(giveawayId);
        final participationResult = await _participationRepository.getMyParticipationForGiveaway(
          giveawayId,
        );
        if (isClosed || generation != _loadGeneration) return;

        final List<GiveawayRequirement> requirements = requirementsResult.fold(
          (_) => const <GiveawayRequirement>[],
          (r) => r,
        );
        await participationResult.fold(
          (_) async => emit(
            state.copyWith(
              status: GiveawayDetailsStatus.loaded,
              giveaway: giveaway,
              requirements: requirements,
              // Keep any previously confirmed entry visible during a
              // transient refresh failure. On first load, `alreadyJoined`
              // is false but the explicit error state still prevents entry.
              participationCheckStatus: ParticipationCheckStatus.error,
            ),
          ),
          (participation) async => emit(
            state.copyWith(
              status: GiveawayDetailsStatus.loaded,
              giveaway: giveaway,
              requirements: requirements,
              alreadyJoined: participation != null,
              participationCheckStatus: participation == null
                  ? ParticipationCheckStatus.notJoined
                  : ParticipationCheckStatus.joined,
              myParticipationNumber: participation?.participationNumber,
              rewardedFrameUnlocked: participation?.rewardedFrameUnlocked ?? false,
            ),
          ),
        );
      },
    );
  }

  /// Called after a successful participation so the CTA flips to "You're
  /// in!" without a full reload.
  void markJoined(int participationNumber) {
    emit(
      state.copyWith(
        alreadyJoined: true,
        participationCheckStatus: ParticipationCheckStatus.joined,
        myParticipationNumber: participationNumber,
      ),
    );
  }

  /// Live status/participant-count updates for this one giveaway while its
  /// details page is open (e.g. an admin ending the giveaway, or the count
  /// climbing as others join), so the user doesn't have to pull-to-refresh.
  /// Scoped to exactly this giveaway's row -- never a blanket subscription
  /// to the whole `giveaways` table. Call once per page instance; a second
  /// call while already subscribed is a no-op, and [close] tears the
  /// channel down. The reload this triggers uses [load]'s existing
  /// `forceRefresh` write-through, which already keeps the Hive-cached
  /// detail entry in sync -- no separate cache-invalidation step needed.
  void subscribeToRealtime(String giveawayId) {
    if (_channel != null) return;
    _channel = _client
        .channel('giveaway-details-$giveawayId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'giveaways',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: giveawayId,
          ),
          callback: (_) => _scheduleReload(giveawayId),
        )
        .subscribe();
  }

  void _scheduleReload(String giveawayId) {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!isClosed) load(giveawayId, forceRefresh: true);
    });
  }

  @override
  Future<void> close() {
    _statusBoundary?.cancel();
    _reloadDebounce?.cancel();
    final channel = _channel;
    _channel = null;
    if (channel != null) _client.removeChannel(channel);
    return super.close();
  }
}
