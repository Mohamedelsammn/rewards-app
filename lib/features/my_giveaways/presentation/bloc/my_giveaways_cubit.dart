import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../services/secure_storage_service.dart';
import '../../../../shared/repositories/participation_repository.dart';
import 'my_giveaways_state.dart';

class MyGiveawaysCubit extends Cubit<MyGiveawaysState> {
  MyGiveawaysCubit(this._repository, this._client, this._secureStorage)
    : super(const MyGiveawaysState()) {
    // Immediate, local-first update for a participation THIS device just
    // confirmed -- no Realtime round trip needed for an action already
    // known to have succeeded. The Realtime subscriptions below remain the
    // mechanism for changes originating elsewhere (another device/session).
    _participationCreatedSub = _repository.participationCreated.listen((_) {
      load(forceRefresh: true);
    });
  }

  final ParticipationRepository _repository;
  final SupabaseClient _client;
  final SecureStorageService _secureStorage;
  final List<RealtimeChannel> _channels = [];
  Timer? _reloadDebounce;
  final Map<String, Timer> _oneOffDebounce = {};
  StreamSubscription<void>? _participationCreatedSub;

  /// Cache-first for the instant paint (no spinner at all for a warm cache),
  /// but the network read behind it always runs regardless of
  /// [forceRefresh] -- see UserHomeCubit.load's matching doc comment for why
  /// a TTL-valid disk cache can't be trusted as "still correct" on its own:
  /// a giveaway this device participated in can end while nothing was
  /// subscribed to catch it in realtime (this device closed/backgrounded, or
  /// a same-device Admin<->User switch tearing this cubit down and rebuilding
  /// it). [forceRefresh] still controls whether the stale value is shown at
  /// all first (pull-to-refresh skips straight to the spinner instead).
  Future<void> load({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _repository.peekCachedParticipations();
      if (cached != null) {
        emit(
          state.copyWith(
            status: cached.isEmpty ? MyGiveawaysStatus.empty : MyGiveawaysStatus.loaded,
            participations: cached,
          ),
        );
      }
    }
    if (state.participations.isEmpty) {
      emit(state.copyWith(status: MyGiveawaysStatus.loading));
    }
    final result = await _repository.getMyParticipations(forceRefresh: true);
    result.fold(
      (failure) {
        if (state.participations.isEmpty) {
          emit(state.copyWith(status: MyGiveawaysStatus.error, failure: failure));
        }
      },
      (participations) => emit(
        state.copyWith(
          status: participations.isEmpty ? MyGiveawaysStatus.empty : MyGiveawaysStatus.loaded,
          participations: participations,
        ),
      ),
    );
  }

  /// Keeps My Giveaways in sync while it's on screen: a new participation,
  /// a giveaway status change, or this user becoming a winner. Each
  /// subscription is scoped to exactly what this screen needs -- the
  /// user-specific ones are filtered to the caller's own `user_id`; RLS is
  /// still the actual security boundary regardless of this filter. Call once
  /// per page instance; a second call while already subscribed is a no-op,
  /// and [close] tears every channel down.
  Future<void> subscribeToRealtime() async {
    if (_channels.isNotEmpty) return;
    final userId = await _secureStorage.cachedUserId;
    if (userId == null || isClosed) return;

    _channels.add(
      _client
          .channel('my-giveaways-participations-$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'participations',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (_) => _scheduleReload(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'participations',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            // Reward verification attaches its entitlement by updating this
            // user's existing row, so the saved number frame refreshes too.
            callback: (_) => _scheduleReload(),
          )
          .subscribe(),
    );

    // A `winner_announcement` notification is a downstream side effect of
    // the same transaction that inserts into `winners` -- never trusted on
    // its own (see _handleWinnerSignal), but still acted on: if its payload
    // identifies the giveaway, do a targeted single-participation refresh;
    // otherwise fall back to a full reload rather than doing nothing.
    _channels.add(
      _client
          .channel('my-giveaways-winner-notifications-$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: _handleWinnerNotification,
          )
          .subscribe(),
    );

    // Unfiltered on purpose -- a giveaway status change (e.g. ending because
    // a winner was selected) can affect any giveaway this user has already
    // joined, and `giveaways` has no participant-scoped column to filter by.
    // The UPDATE payload already carries the row's full new data, so this
    // patches the one affected card directly instead of reloading everything.
    _channels.add(
      _client
          .channel('my-giveaways-status-$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'giveaways',
            callback: _handleGiveawayStatusUpdate,
          )
          .subscribe(),
    );

    // Direct, server-authoritative winner signal: `winners` is exactly what
    // fn_select_winner writes, in the same transaction as the giveaway
    // status change and the notification above -- not filtered to this user
    // (the table has no user_id column), so membership is checked against
    // this user's already-loaded participations before acting. This is what
    // keeps My Giveaways from depending solely on the notification row to
    // learn about a win.
    _channels.add(
      _client
          .channel('my-giveaways-winners-$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'winners',
            callback: _handleWinnerInsert,
          )
          .subscribe(),
    );
  }

  void _handleGiveawayStatusUpdate(PostgresChangePayload payload) {
    final newRecord = payload.newRecord;
    final giveawayId = newRecord['id'] as String?;
    if (giveawayId == null || newRecord.isEmpty) {
      _scheduleReload();
      return;
    }
    final index = state.participations.indexWhere((p) => p.giveawayId == giveawayId);
    if (index == -1) return; // Not one of my giveaways -- nothing to patch.

    final next = List.of(state.participations);
    final participationId = next[index].id;
    next[index] = next[index].copyWith(giveaway: newRecord);
    emit(state.copyWith(participations: next));
    unawaited(_repository.patchCachedParticipationGiveaway(participationId, newRecord));
  }

  void _handleWinnerInsert(PostgresChangePayload payload) {
    final giveawayId = payload.newRecord['giveaway_id'] as String?;
    if (giveawayId == null) return;
    final isMine = state.participations.any((p) => p.giveawayId == giveawayId);
    if (!isMine) return;
    _scheduleRefreshOne(giveawayId);
  }

  void _handleWinnerNotification(PostgresChangePayload payload) {
    final data = payload.newRecord['data'];
    final giveawayId = data is Map ? data['giveawayId'] as String? : null;
    if (giveawayId == null) {
      _scheduleReload();
      return;
    }
    _scheduleRefreshOne(giveawayId);
  }

  /// Re-confirms exactly one giveaway's participation from the server (see
  /// [ParticipationRepository.getMyParticipationWithStatusForGiveaway]) --
  /// the server, not the realtime payload that triggered this, decides
  /// whether this device actually won. Debounced per-giveaway so a winner
  /// INSERT and its companion notification (same transaction, both usually
  /// arriving within milliseconds of each other) collapse into one request.
  void _scheduleRefreshOne(String giveawayId) {
    _oneOffDebounce[giveawayId]?.cancel();
    _oneOffDebounce[giveawayId] = Timer(const Duration(milliseconds: 500), () {
      _oneOffDebounce.remove(giveawayId);
      if (!isClosed) unawaited(_refreshOneGiveaway(giveawayId));
    });
  }

  Future<void> _refreshOneGiveaway(String giveawayId) async {
    final result = await _repository.getMyParticipationWithStatusForGiveaway(giveawayId);
    if (isClosed) return;
    result.fold((_) {}, (participation) {
      if (participation == null) return;
      final index = state.participations.indexWhere((p) => p.giveawayId == giveawayId);
      if (index == -1) return;
      final next = List.of(state.participations);
      next[index] = participation;
      emit(state.copyWith(participations: next));
    });
  }

  void _scheduleReload() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!isClosed) load(forceRefresh: true);
    });
  }

  @override
  Future<void> close() {
    _reloadDebounce?.cancel();
    for (final timer in _oneOffDebounce.values) {
      timer.cancel();
    }
    _oneOffDebounce.clear();
    _participationCreatedSub?.cancel();
    for (final channel in _channels) {
      _client.removeChannel(channel);
    }
    _channels.clear();
    return super.close();
  }
}
