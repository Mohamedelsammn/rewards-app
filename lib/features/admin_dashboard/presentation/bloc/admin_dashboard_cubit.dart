import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/models/giveaway.dart';
import '../../../../shared/repositories/giveaway_repository.dart';
import '../../../../shared/repositories/winner_repository.dart';
import 'admin_dashboard_state.dart';

/// Admin data is correctness-first, not cache-first (implementation-plan.md's
/// caching brief explicitly calls this out) -- always reads live.
class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit(this._giveawayRepository, this._client, this._winnerRepository)
    : super(const AdminDashboardState()) {
    // Immediate, local-first reload the moment THIS admin session confirms
    // creating a giveaway or selecting a winner -- no Realtime round trip
    // needed for an action already known to have succeeded. The Realtime
    // subscription below (see [subscribeToRealtime]) remains the mechanism
    // for changes originating elsewhere (a second admin device/session).
    _giveawayCreatedSub = _giveawayRepository.giveawayCreated.listen((_) => load());
    _winnerSelectedSub = _winnerRepository.winnerSelected.listen((_) => load());
  }

  final GiveawayRepository _giveawayRepository;
  final SupabaseClient _client;
  final WinnerRepository _winnerRepository;
  StreamSubscription<Giveaway>? _giveawayCreatedSub;
  StreamSubscription<dynamic>? _winnerSelectedSub;
  RealtimeChannel? _channel;
  Timer? _reloadDebounce;

  Future<void> load() async {
    emit(state.copyWith(status: AdminDashboardStatus.loading));

    // Scoped to the calling admin's own giveaways (implementation-plan.md's
    // admin isolation requirement) -- never another admin's campaigns, even
    // though those may individually be public-readable.
    final giveawaysResult = await _giveawayRepository.getMyAdminGiveaways();

    await giveawaysResult.fold(
      (failure) async => emit(state.copyWith(status: AdminDashboardStatus.error, failure: failure)),
      (giveaways) async {
        final active = giveaways.where((g) => g.effectiveStatus == GiveawayStatus.active).toList();
        final upcoming = giveaways
            .where((g) => g.effectiveStatus == GiveawayStatus.scheduled)
            .toList();
        // Ended giveaways must remain reachable (not just counted) so the
        // admin can still open a finished campaign to see its winner(s) and
        // analytics -- see docs/fixes/state-sync-and-session-restoration.md.
        final ended = giveaways.where((g) => g.effectiveStatus == GiveawayStatus.ended).toList();
        final totalParticipants = giveaways.fold<int>(0, (sum, g) => sum + g.participantCount);

        int winnersCount = 0;
        final authUid = _client.auth.currentUser?.id;
        if (authUid != null) {
          try {
            // selected_by, not just any row in `winners` (which is publicly
            // readable) -- scopes the stat to winners *this admin* picked.
            final winnersRows = await _client
                .from('winners')
                .select('id')
                .eq('selected_by', authUid);
            winnersCount = (winnersRows as List).length;
          } catch (_) {
            // Non-fatal -- dashboard still renders with 0 if this read fails.
          }
        }

        emit(
          state.copyWith(
            status: AdminDashboardStatus.loaded,
            activeCount: active.length,
            finishedCount: ended.length,
            totalParticipants: totalParticipants,
            winnersSelectedCount: winnersCount,
            activeCampaigns: active,
            upcomingCampaigns: upcoming,
            endedCampaigns: ended,
          ),
        );
      },
    );
  }

  /// Cross-device/cross-session sync: catches a giveaway created or updated
  /// by this same admin on a *different* device/tab. Scoped to exactly this
  /// admin's own giveaways (`created_by = eq.<adminId>`) -- never a blanket
  /// subscription to every admin's data. Call once per page instance; a
  /// second call while already subscribed is a no-op, and [close] tears the
  /// channel down.
  void subscribeToRealtime() {
    if (_channel != null) return;
    final adminId = _client.auth.currentUser?.id;
    if (adminId == null) return;

    _channel = _client
        .channel('admin-dashboard-giveaways-$adminId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'giveaways',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'created_by',
            value: adminId,
          ),
          callback: (_) => _scheduleReload(),
        )
        .subscribe();
  }

  void _scheduleReload() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!isClosed) load();
    });
  }

  @override
  Future<void> close() {
    _reloadDebounce?.cancel();
    _giveawayCreatedSub?.cancel();
    _winnerSelectedSub?.cancel();
    final channel = _channel;
    _channel = null;
    if (channel != null) _client.removeChannel(channel);
    return super.close();
  }
}
