import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../services/cache/cache_keys.dart';
import '../../services/cache/cache_service.dart';
import '../models/participation.dart';

/// Wraps `create-participation` (the sole server-authoritative write for
/// joining a giveaway) plus read access to the caller's own participations.
/// V1 has no advertisement system -- participation creation is a single
/// direct call, not gated behind an ad-reward round trip. Nothing here is
/// cached as "safe to serve stale" for the write path -- it always hits the
/// network (implementation-plan.md: participation creation must remain
/// server-authoritative, never cached).
class ParticipationRepository {
  ParticipationRepository(this._client, this._cache);

  final SupabaseClient _client;
  final CacheService _cache;

  Future<Result<Participation>> createParticipation({required String giveawayId}) async {
    try {
      final response = await _client.functions.invoke(
        'create-participation',
        body: {'giveawayId': giveawayId},
      );

      final data = response.data;
      if (response.status != 200 || data is! Map || data['participationId'] == null) {
        final code = (data is Map ? data['code'] as String? : null) ?? 'server_error';
        final message = data is Map ? data['message'] as String? : null;
        return Result.failure(failureFromEdgeFunctionCode(code, message));
      }

      await _cache.invalidate(CacheKeys.myParticipations);

      return Result.success(
        Participation.fromJson({...Map<String, dynamic>.from(data), 'giveaway_id': giveawayId}),
      );
    } on FunctionException catch (e) {
      return Result.failure(_mapFunctionException(e));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  Future<Result<List<Participation>>> getMyParticipations({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _cache.read<List<Participation>>(
        CacheKeys.myParticipations,
        (json) => (json as List)
            .map((e) => Participation.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
      if (cached != null) return Result.success(cached);
    }

    try {
      final rows = await _client
          .from('participations')
          .select('*, giveaways(*)')
          .order('created_at', ascending: false);

      final participations = (rows as List)
          .map((e) => Participation.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      await _cache.write(CacheKeys.myParticipations, rows, ttl: CacheKeys.myParticipationsTtl);

      return Result.success(participations);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  /// Used by Giveaway Details to render "You're in!" instead of re-offering
  /// "Generate My Number" (tasks.md T09-06) without fetching the whole list.
  Future<Result<Participation?>> getMyParticipationForGiveaway(String giveawayId) async {
    try {
      final row = await _client
          .from('participations')
          .select()
          .eq('giveaway_id', giveawayId)
          .maybeSingle();

      if (row == null) return const Result.success(null);
      return Result.success(Participation.fromJson(Map<String, dynamic>.from(row)));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  Future<Result<void>> markScratchRevealed(String participationId) async {
    try {
      await _client
          .from('participations')
          .update({'scratch_revealed_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', participationId);
      await _cache.invalidate(CacheKeys.myParticipations);
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  Failure _mapFunctionException(FunctionException e) {
    final data = e.details;
    final code = (data is Map ? data['code'] as String? : null) ?? 'server_error';
    final message = data is Map ? data['message'] as String? : e.toString();
    return failureFromEdgeFunctionCode(code, message);
  }
}
