import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/repositories/giveaway_repository.dart';
import '../../../../shared/repositories/winner_repository.dart';
import 'giveaway_analytics_state.dart';

/// Correctness-first (no cache) -- an admin picking a winner needs to see
/// the true current participant count, not a stale cached one.
class GiveawayAnalyticsCubit extends Cubit<GiveawayAnalyticsState> {
  GiveawayAnalyticsCubit(this._giveawayRepository, this._winnerRepository, this._client)
    : super(const GiveawayAnalyticsState());

  final GiveawayRepository _giveawayRepository;
  final WinnerRepository _winnerRepository;
  final SupabaseClient _client;

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
              .select('participation_sequence, created_at, users(full_name)')
              .eq('giveaway_id', giveawayId)
              .order('created_at', ascending: false);

          final allRows = List<Map<String, dynamic>>.from(participantRows as List);

          final recent = allRows
              .take(20)
              .map(
                (row) => RecentParticipant(
                  participationSequence: row['participation_sequence'] as int,
                  fullName: (row['users'] as Map?)?['full_name'] as String? ?? 'Anonymous',
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

  Future<String?> selectWinner(String giveawayId, {String? participationId}) async {
    emit(state.copyWith(isSelectingWinner: true));
    final result = await _winnerRepository.selectWinner(
      giveawayId: giveawayId,
      participationId: participationId,
    );
    emit(state.copyWith(isSelectingWinner: false));
    return result.fold(
      (failure) {
        emit(state.copyWith(failure: failure));
        return null;
      },
      (_) {
        load(giveawayId);
        return null;
      },
    );
  }
}
