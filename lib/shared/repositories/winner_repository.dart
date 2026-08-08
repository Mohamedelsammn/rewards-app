import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../models/winner.dart';

/// Winner selection (wraps `admin-select-winner`) plus the read paths behind
/// the winner celebration (implementation-plan.md §14, and the top-anchored
/// winner-celebration requirement). `celebration_acknowledged_at` is the
/// server-authoritative "seen" flag -- the celebration must fire exactly
/// once per win, survive app restarts/offline gaps, and never replay once
/// acknowledged.
class WinnerRepository {
  WinnerRepository(this._client);

  final SupabaseClient _client;

  /// The caller's own oldest unacknowledged win, if any. Scoped by an
  /// explicit `user_id` filter (not RLS) because `winners` is intentionally
  /// publicly readable for announcements -- RLS can't narrow "mine" here.
  Future<Result<Winner?>> getMyPendingWinner(String userId) async {
    try {
      final rows = await _client
          .from('winners')
          .select(
            '*, giveaways(title, image_url), participations!inner(user_id, participation_number)',
          )
          .eq('participations.user_id', userId)
          .filter('celebration_acknowledged_at', 'is', null)
          .order('selected_at')
          .limit(1);

      final list = rows as List;
      if (list.isEmpty) return const Result.success(null);
      return Result.success(Winner.fromJson(Map<String, dynamic>.from(list.first as Map)));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  Future<Result<void>> acknowledgeCelebration(String winnerId) async {
    try {
      await _client
          .from('winners')
          .update({'celebration_acknowledged_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', winnerId);
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  Future<Result<List<Winner>>> getWinnersForGiveaway(String giveawayId) async {
    try {
      final rows = await _client
          .from('winners')
          .select('*, participations(participation_number)')
          .eq('giveaway_id', giveawayId)
          .order('rank');
      return Result.success(
        (rows as List).map((e) => Winner.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      );
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  /// [participationId] null = server picks uniformly at random among
  /// eligible participants; provided = manual pick.
  Future<Result<Winner>> selectWinner({required String giveawayId, String? participationId}) async {
    try {
      final response = await _client.functions.invoke(
        'admin-select-winner',
        body: {
          'giveawayId': giveawayId,
          if (participationId != null) 'participationId': participationId,
        },
      );

      final data = response.data;
      if (response.status != 200 || data is! Map || data['winnerId'] == null) {
        final code = (data is Map ? data['code'] as String? : null) ?? 'server_error';
        final message = data is Map ? data['message'] as String? : null;
        return Result.failure(_mapError(code, message));
      }

      final map = Map<String, dynamic>.from(data);
      return Result.success(
        Winner(
          id: map['winnerId'] as String,
          giveawayId: giveawayId,
          participationId: map['participationId'] as String,
          rank: 1,
          selectedAt: DateTime.parse(map['selectedAt'] as String),
          celebrationAcknowledgedAt: null,
          participationNumber: map['participationNumber'] as int?,
        ),
      );
    } on FunctionException catch (e) {
      final data = e.details;
      final code = (data is Map ? data['code'] as String? : null) ?? 'server_error';
      final message = data is Map ? data['message'] as String? : e.toString();
      return Result.failure(_mapError(code, message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  Failure _mapError(String code, String? message) {
    switch (code) {
      case 'not_an_admin':
      case 'unauthorized':
        return const UnauthorizedFailure('You are not authorized to select a winner.');
      case 'no_eligible_participants':
        return const ValidationFailure('There are no eligible participants left to select.');
      case 'already_a_winner':
        return const ValidationFailure('This participant has already been selected as a winner.');
      case 'giveaway_not_found':
      case 'participation_not_found':
        return const ValidationFailure('Could not find that giveaway or participant.');
      default:
        return ServerFailure(message ?? 'Something went wrong. Please try again.');
    }
  }
}
