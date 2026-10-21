import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/models/giveaway.dart';
import '../../../../shared/repositories/giveaway_repository.dart';
import '../../../../shared/repositories/winner_repository.dart';
import 'admin_analysis_state.dart';

/// Overall, admin-level analytics -- aggregated across every giveaway the
/// CALLING admin owns, never another admin's data. [GiveawayRepository.
/// getMyAdminGiveaways] is already `created_by = auth.uid()` scoped (backed
/// by the `giveaways_select_public`/`giveaways_admin_*` RLS policies, not
/// just this client-side filter), and the `winners`/`participations` reads
/// below are scoped the same way the existing per-giveaway analytics and
/// dashboard cubits already do -- no new isolation mechanism, no
/// aggregation across admins.
class AdminAnalysisCubit extends Cubit<AdminAnalysisState> {
  AdminAnalysisCubit(this._giveawayRepository, this._client, this._winnerRepository)
    : super(const AdminAnalysisState()) {
    // Same "immediate local update, Realtime is for elsewhere" split as
    // AdminDashboardCubit -- this tab is a sibling kept alive in the same
    // AdminShell IndexedStack, so without this it would keep showing stale
    // totals after a giveaway is created or a winner is selected from the
    // Dashboard tab until a manual pull-to-refresh.
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
    emit(state.copyWith(status: AdminAnalysisStatus.loading));

    final giveawaysResult = await _giveawayRepository.getMyAdminGiveaways();

    await giveawaysResult.fold(
      (failure) async => emit(state.copyWith(status: AdminAnalysisStatus.error, failure: failure)),
      (giveaways) async {
        if (giveaways.isEmpty) {
          emit(state.copyWith(status: AdminAnalysisStatus.empty));
          return;
        }

        final active = giveaways.where((g) => g.status == GiveawayStatus.active).length;
        final finished = giveaways.where((g) => g.status == GiveawayStatus.ended).length;
        final totalParticipants = giveaways.fold<int>(0, (sum, g) => sum + g.participantCount);

        final authUid = _client.auth.currentUser?.id;
        var totalWinners = 0;
        if (authUid != null) {
          try {
            // selected_by, not just any row in `winners` (which is publicly
            // readable) -- scopes the stat to winners *this admin* picked.
            final winnerRows = await _client
                .from('winners')
                .select('id')
                .eq('selected_by', authUid);
            totalWinners = (winnerRows as List).length;
          } catch (_) {
            // Non-fatal -- page still renders with 0 if this read fails.
          }
        }

        final dailyGrowth = List<int>.filled(7, 0);
        try {
          final ids = giveaways.map((g) => g.id).toList();
          // participations_select_own's admin clause (fn_owns_giveaway) is
          // the actual isolation boundary here -- this query can never
          // return another admin's participation rows even without the
          // `.inFilter`, but the filter also keeps the result to exactly
          // this admin's own giveaways rather than every giveaway RLS
          // happens to let them read.
          final participationRows = await _client
              .from('participations')
              .select('created_at')
              .inFilter('giveaway_id', ids);

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          for (final row in (participationRows as List)) {
            final createdAt = DateTime.parse(row['created_at'] as String).toLocal();
            final daysAgo = today
                .difference(DateTime(createdAt.year, createdAt.month, createdAt.day))
                .inDays;
            if (daysAgo >= 0 && daysAgo < 7) {
              dailyGrowth[6 - daysAgo]++;
            }
          }
        } catch (_) {
          // Non-fatal -- stat cards still render even if the trend read fails.
        }

        emit(
          state.copyWith(
            status: AdminAnalysisStatus.loaded,
            totalGiveaways: giveaways.length,
            activeCount: active,
            finishedCount: finished,
            totalParticipants: totalParticipants,
            totalWinners: totalWinners,
            dailyGrowth: dailyGrowth,
          ),
        );
      },
    );
  }

  /// Cross-device/cross-session sync, mirroring [AdminDashboardCubit]'s
  /// subscription exactly -- scoped to this admin's own giveaways only.
  void subscribeToRealtime() {
    if (_channel != null) return;
    final adminId = _client.auth.currentUser?.id;
    if (adminId == null) return;

    _channel = _client
        .channel('admin-analysis-giveaways-$adminId')
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
