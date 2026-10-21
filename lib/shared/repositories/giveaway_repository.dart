import 'dart:async';

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

  static const browsePageSize = 24;
  Future<Result<List<Giveaway>>> getBrowsePage({
    int page = 0,
    String query = '',
    String? categoryId,
  }) async {
    try {
      var request = _client.from('giveaways').select().inFilter('status', [
        'scheduled',
        'active',
        'ended',
      ]);
      if (categoryId != null) request = request.eq('category_id', categoryId);
      final term = query.trim();
      if (term.isNotEmpty) {
        final literal = term.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');
        request = request.ilike('title', '%$literal%');
      }
      final rows = await request
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .range(page * browsePageSize, (page + 1) * browsePageSize - 1);
      return Result.success(rows.map(Giveaway.fromJson).toList());
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  final _giveawayCreatedController = StreamController<Giveaway>.broadcast();

  /// Fires the moment a giveaway is confirmed created by THIS admin session
  /// -- the local, already-confirmed-success signal listeners (Admin
  /// Dashboard, Admin Analysis) should act on immediately rather than
  /// waiting on a Realtime round trip for an action already known to have
  /// succeeded. Realtime remains the mechanism for changes originating
  /// elsewhere (a second admin device/session).
  Stream<Giveaway> get giveawayCreated => _giveawayCreatedController.stream;

  /// Synchronous, cache-only read (no network fallback, never emits any
  /// loading state on its own) -- lets a cubit seed its very first frame
  /// with existing data so a warm cache never shows a loading spinner, not
  /// even for a single frame. Returns null on a cold/expired cache; callers
  /// fall back to [getGiveaways] for the real (network-backed) read.
  List<Giveaway>? peekCachedGiveaways() {
    return _cache.read<List<Giveaway>>(
      CacheKeys.giveawayList,
      (json) => (json as List)
          .map((e) => Giveaway.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  /// Same as [peekCachedGiveaways] but for a single giveaway's detail cache.
  Giveaway? peekCachedGiveaway(String id) {
    return _cache.read<Giveaway>(
      CacheKeys.giveawayDetails(id),
      (json) => Giveaway.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

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

  /// Admin dashboard/management use ONLY -- explicitly scoped to the
  /// calling admin's own giveaways (`created_by = auth.uid()`), never
  /// cached under the shared `CacheKeys.giveawayList` key.
  ///
  /// This is a view-scoping filter layered on top of RLS, not the security
  /// boundary itself: `giveaways_select_public` already prevents any admin
  /// from reading another admin's unpublished giveaways at the database
  /// level. Without this filter, though, RLS would still correctly return
  /// *other* admins' *published* giveaways alongside this admin's own (that
  /// data really is public), which is wrong for a "my campaigns" dashboard
  /// -- and caching that mixed result under the public list's shared key
  /// would leak an admin's own draft giveaways into a regular user's
  /// cached Home screen the next time that key is read. Always live, no
  /// caching, matching this repository's existing "admin data is
  /// correctness-first" posture.
  Future<Result<List<Giveaway>>> getMyAdminGiveaways() async {
    final authUid = _client.auth.currentUser?.id;
    if (authUid == null) return const Result.failure(UnauthorizedFailure());

    try {
      final rows = await _client
          .from('giveaways')
          .select()
          .eq('created_by', authUid)
          .order('created_at', ascending: false);

      return Result.success(
        (rows as List).map((e) => Giveaway.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      );
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

  /// Patches ONE giveaway's fields into whatever this device already has
  /// cached -- the list cache and this giveaway's own details cache, each
  /// only if already warm -- without touching any other cached entry or
  /// resetting the whole box. Used by [UserHomeCubit]'s realtime handler to
  /// apply a row Postgres already sent the full new data for, instead of
  /// re-fetching the entire list for a single-row change.
  Future<void> patchCachedGiveaway(Giveaway giveaway) async {
    final cachedList = peekCachedGiveaways();
    if (cachedList != null) {
      final index = cachedList.indexWhere((g) => g.id == giveaway.id);
      if (index != -1) {
        final next = List<Giveaway>.of(cachedList);
        next[index] = giveaway;
        await _cache.write(
          CacheKeys.giveawayList,
          next.map((g) => g.toJson()).toList(),
          ttl: CacheKeys.giveawayListTtl,
        );
      }
    }

    if (peekCachedGiveaway(giveaway.id) != null) {
      await _cache.write(
        CacheKeys.giveawayDetails(giveaway.id),
        giveaway.toJson(),
        ttl: CacheKeys.giveawayDetailsTtl,
      );
    }
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
    String? categoryId,
    DateTime? startsAt,
    DateTime? endsAt,
    String? editingId,
  }) async {
    try {
      // The UTC columns are canonical after the scheduling trigger runs.
      // On edit, keep legacy date/time columns in that same UTC frame so an
      // unchanged local-time schedule does not look like a reschedule (or
      // get shifted to midnight by the legacy-client compatibility trigger).
      final storedStart = editingId != null && startsAt != null ? startsAt.toUtc() : startDate;
      final storedEnd = editingId != null && endsAt != null ? endsAt.toUtc() : endDate;
      final storedEndTime = editingId != null && endsAt != null
          ? '${endsAt.toUtc().hour.toString().padLeft(2, '0')}:${endsAt.toUtc().minute.toString().padLeft(2, '0')}'
          : endTime;
      final values = <String, dynamic>{
        'title': title,
        'organizer_name': organizerName,
        'prize_description': prizeDescription,
        'description_rules': descriptionRules,
        'image_url': imageUrl,
        'start_date': storedStart.toIso8601String().split('T').first,
        'end_date': storedEnd.toIso8601String().split('T').first,
        'end_time': storedEndTime,
        if (editingId == null)
          'status': (startsAt ?? startDate).isAfter(DateTime.now()) ? 'scheduled' : 'active',
        'category_id': categoryId,
        if (startsAt != null) 'starts_at': startsAt.toUtc().toIso8601String(),
        if (endsAt != null) 'ends_at': endsAt.toUtc().toIso8601String(),
        if (editingId == null) 'number_digit_width': numberDigitWidth,
        if (editingId == null) 'created_by': createdByAdminId,
      };
      final row = editingId == null
          ? await _client.from('giveaways').insert(values).select().single()
          : await _client
                .from('giveaways')
                .update(values)
                .eq('id', editingId)
                .eq('created_by', createdByAdminId)
                .select()
                .single();

      await _cache.invalidate(CacheKeys.giveawayList);
      final giveaway = Giveaway.fromJson(Map<String, dynamic>.from(row));
      if (editingId != null) await _cache.invalidate(CacheKeys.giveawayDetails(editingId));
      _giveawayCreatedController.add(giveaway);
      return Result.success(giveaway);
    } on PostgrestException catch (e) {
      if (e.message.contains('giveaway_schedule_locked')) {
        return const Result.failure(GiveawayScheduleLockedFailure());
      }
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

  /// TRUE hard delete of a giveaway and every DB record that belongs
  /// exclusively to it (participations, winners, and other giveaway-scoped
  /// rows) -- never the global users who participated. Routed through
  /// `fn_admin_delete_giveaway`, a SECURITY DEFINER Postgres function that
  /// resolves the caller and ownership entirely from `auth.uid()` server-
  /// side (never a client-supplied admin id) and performs the delete as one
  /// atomic transaction: every `giveaway_id`-scoped table already has `ON
  /// DELETE CASCADE`, and the function additionally scrubs the giveaway's
  /// `winner_announcement` notification rows (which reference it only via
  /// jsonb `data`, not a real FK). If the admin doesn't own the giveaway,
  /// or it no longer exists, the function raises and nothing is deleted.
  Future<Result<void>> deleteGiveaway(String giveawayId) async {
    try {
      await _client.rpc('fn_admin_delete_giveaway', params: {'p_giveaway_id': giveawayId});
      await _cache.invalidate(CacheKeys.giveawayDetails(giveawayId));
      await _cache.invalidate(CacheKeys.giveawayList);
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(_mapDeleteError(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  Failure _mapDeleteError(String code) {
    switch (code) {
      case 'not_an_admin':
      case 'not_giveaway_owner':
        return const UnauthorizedFailure('You can only delete your own giveaways.');
      case 'giveaway_not_found':
        return const ValidationFailure('This giveaway no longer exists.');
      default:
        return ServerFailure(code);
    }
  }
}
