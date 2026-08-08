import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/models/giveaway.dart';
import '../../../../shared/repositories/giveaway_repository.dart';
import 'admin_dashboard_state.dart';

/// Admin data is correctness-first, not cache-first (implementation-plan.md's
/// caching brief explicitly calls this out) -- always reads live.
class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit(this._giveawayRepository, this._client) : super(const AdminDashboardState());

  final GiveawayRepository _giveawayRepository;
  final SupabaseClient _client;

  Future<void> load() async {
    emit(state.copyWith(status: AdminDashboardStatus.loading));

    final giveawaysResult = await _giveawayRepository.getGiveaways(forceRefresh: true);

    await giveawaysResult.fold(
      (failure) async => emit(state.copyWith(status: AdminDashboardStatus.error, failure: failure)),
      (giveaways) async {
        final active = giveaways.where((g) => g.status == GiveawayStatus.active).toList();
        final finished = giveaways.where((g) => g.status == GiveawayStatus.ended).length;
        final totalParticipants = giveaways.fold<int>(0, (sum, g) => sum + g.participantCount);

        int winnersCount = 0;
        try {
          final winnersRows = await _client.from('winners').select('id');
          winnersCount = (winnersRows as List).length;
        } catch (_) {
          // Non-fatal -- dashboard still renders with 0 if this read fails.
        }

        emit(
          state.copyWith(
            status: AdminDashboardStatus.loaded,
            activeCount: active.length,
            finishedCount: finished,
            totalParticipants: totalParticipants,
            winnersSelectedCount: winnersCount,
            activeCampaign: active.isNotEmpty ? active.first : null,
          ),
        );
      },
    );
  }
}
