import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../services/cache/cache_keys.dart';
import '../../services/cache/cache_service.dart';
import '../models/giveaway.dart';
import '../models/giveaway_requirement.dart';

/// Cache-first reads in front of `giveaways` / `giveaway_requirements`.
/// Giveaway data is classified semi-static (implementation-plan.md's
/// caching brief) -- safe to serve from Hive within the TTL window without
/// hitting Supabase at all. `forceRefresh` (pull-to-refresh) always bypasses
/// the cache and re-primes it.
class GiveawayRepository {
  GiveawayRepository(this._client, this._cache);

  final SupabaseClient _client;
  final CacheService _cache;

  Future<Result<List<Giveaway>>> getGiveaways({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _cache.read<List<Giveaway>>(
        CacheKeys.giveawayList,
        (json) => (json as List)
            .map((e) => Giveaway.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
      if (cached != null) return Result.success(cached);
    }

    try {
      final rows = await _client.from('giveaways').select().order('created_at', ascending: false);

      final giveaways = (rows as List)
          .map((e) => Giveaway.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      await _cache.write(
        CacheKeys.giveawayList,
        giveaways.map((g) => g.toJson()).toList(),
        ttl: CacheKeys.giveawayListTtl,
      );

      return Result.success(giveaways);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  Future<Result<Giveaway>> getGiveawayById(String id, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _cache.read<Giveaway>(
        CacheKeys.giveawayDetails(id),
        (json) => Giveaway.fromJson(Map<String, dynamic>.from(json as Map)),
      );
      if (cached != null) return Result.success(cached);
    }

    try {
      final row = await _client.from('giveaways').select().eq('id', id).single();
      final giveaway = Giveaway.fromJson(Map<String, dynamic>.from(row));

      await _cache.write(
        CacheKeys.giveawayDetails(id),
        giveaway.toJson(),
        ttl: CacheKeys.giveawayDetailsTtl,
      );

      return Result.success(giveaway);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  Future<Result<List<GiveawayRequirement>>> getRequirements(String giveawayId) async {
    try {
      final rows = await _client
          .from('giveaway_requirements')
          .select()
          .eq('giveaway_id', giveawayId)
          .order('sort_order');

      return Result.success(
        (rows as List)
            .map((e) => GiveawayRequirement.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  /// Called after a successful participation so the details/list screens
  /// don't show a stale participant_count for up to the full TTL.
  Future<void> invalidateAfterParticipation(String giveawayId) async {
    await _cache.invalidate(CacheKeys.giveawayDetails(giveawayId));
    await _cache.invalidate(CacheKeys.giveawayList);
  }

  /// Direct RLS-guarded insert (implementation-plan.md §8.1) -- the
  /// `giveaways_admin_insert` policy only allows this for `fn_is_admin()`
  /// callers, so no Edge Function is needed here.
  Future<Result<Giveaway>> createGiveaway({
    required String title,
    required String organizerName,
    required String prizeDescription,
    required String descriptionRules,
    String? imageUrl,
    required DateTime startDate,
    required DateTime endDate,
    required String endTime,
    required String createdByAdminId,
    int numberDigitWidth = 4,
  }) async {
    try {
      final row = await _client
          .from('giveaways')
          .insert({
            'title': title,
            'organizer_name': organizerName,
            'prize_description': prizeDescription,
            'description_rules': descriptionRules,
            'image_url': imageUrl,
            'start_date': startDate.toIso8601String().split('T').first,
            'end_date': endDate.toIso8601String().split('T').first,
            'end_time': endTime,
            'status': 'active',
            'number_digit_width': numberDigitWidth,
            'created_by': createdByAdminId,
          })
          .select()
          .single();

      await _cache.invalidate(CacheKeys.giveawayList);
      return Result.success(Giveaway.fromJson(Map<String, dynamic>.from(row)));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  Future<Result<void>> updateGiveawayStatus(String giveawayId, String status) async {
    try {
      await _client.from('giveaways').update({'status': status}).eq('id', giveawayId);
      await _cache.invalidate(CacheKeys.giveawayDetails(giveawayId));
      await _cache.invalidate(CacheKeys.giveawayList);
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }
}
