import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../services/cache/cache_keys.dart';
import '../../services/cache/cache_service.dart';
import '../../services/reward_frame_entitlement_store.dart';
import '../models/participation.dart';

/// Wraps `create-participation` (the sole server-authoritative write for
/// joining a giveaway) plus read access to the caller's own participations.
/// Cosmetic rewarded-frame entitlements are stored locally and scoped to the
/// active auth identity. Participation creation remains server-authoritative
/// and is never cached.
class ParticipationRepository {
  ParticipationRepository(this._client, this._cache, this._frameEntitlements);

  final SupabaseClient _client;
  final CacheService _cache;
  final RewardFrameEntitlementStore _frameEntitlements;

  final _participationCreatedController = StreamController<Participation>.broadcast();

  /// Fires the moment a participation is confirmed created by THIS device --
  /// the "local, already-confirmed-success" signal a listener (My
  /// Giveaways) should act on immediately, instead of waiting on a Realtime
  /// round trip for an action it already knows succeeded. Realtime remains
  /// the mechanism for changes originating elsewhere (another device,
  /// another session) -- this stream is purely additive, not a replacement.
  Stream<Participation> get participationCreated => _participationCreatedController.stream;

  /// The cache key for `getMyParticipations` must be scoped by identity
  /// (see [CacheKeys.myParticipations]); null only if there's genuinely no
  /// session, in which case every RLS-guarded call below would fail anyway,
  /// so skipping the cache in that case is harmless.
  String? get _myParticipationsCacheKey {
    final authUid = _client.auth.currentUser?.id;
    return authUid == null ? null : CacheKeys.myParticipations(authUid);
  }

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

      final cacheKey = _myParticipationsCacheKey;
      if (cacheKey != null) await _cache.invalidate(cacheKey);

      final participation = Participation.fromJson({
        ...Map<String, dynamic>.from(data),
        'giveaway_id': giveawayId,
      });
      final hydrated = _withLocalFrame(participation);
      _participationCreatedController.add(hydrated);

      return Result.success(hydrated);
    } on FunctionException catch (e) {
      return Result.failure(_mapFunctionException(e));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  Future<void> markRewardFrameEarned(String giveawayId) =>
      _frameEntitlements.markEarned(giveawayId);

  bool hasPendingRewardFrame(String giveawayId) => _frameEntitlements.hasPending(giveawayId);

  Future<void> attachRewardFrameToParticipation({
    required String giveawayId,
    required String participationId,
  }) => _frameEntitlements.attach(giveawayId, participationId);

  bool hasRewardFrameEntitlement({required String giveawayId, required String participationId}) =>
      _frameEntitlements.hasEntitlement(giveawayId, participationId);

  Participation _withLocalFrame(Participation participation) {
    if (participation.rewardedFrameUnlocked ||
        !_frameEntitlements.hasEntitlement(participation.giveawayId, participation.id)) {
      return participation;
    }
    return participation.copyWith(rewardedFrameUnlocked: true);
  }

  /// Synchronous, cache-only read (no network fallback) -- lets
  /// [MyGiveawaysCubit] seed its very first frame with existing data so a
  /// warm cache never shows a loading spinner, matching
  /// GiveawayRepository.peekCachedGiveaways. Returns null on a cold/expired
  /// cache or with no session; callers fall back to [getMyParticipations]
  /// for the real (network-backed) read.
  List<Participation>? peekCachedParticipations() {
    final cacheKey = _myParticipationsCacheKey;
    if (cacheKey == null) return null;
    final cached = _cache.read<List<Participation>>(
      cacheKey,
      (json) => (json as List)
          .map((e) => Participation.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
    return cached?.map(_withLocalFrame).toList(growable: false);
  }

  Future<Result<List<Participation>>> getMyParticipations({bool forceRefresh = false}) async {
    final cacheKey = _myParticipationsCacheKey;

    if (!forceRefresh && cacheKey != null) {
      final cached = _cache.read<List<Participation>>(
        cacheKey,
        (json) => (json as List)
            .map((e) => Participation.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
      if (cached != null) {
        return Result.success(cached.map(_withLocalFrame).toList(growable: false));
      }
    }

    try {
      // `winners(id)` embeds via the winners.participation_id FK -- a
      // non-empty list means this participation won (see Participation.
      // isWinner), which is what lets My Giveaways show "You Won" vs. "Not
      // Selected" for a finished giveaway without a second round trip.
      final rows = await _client
          .from('participations')
          .select('*, giveaways(*), winners(id)')
          .order('created_at', ascending: false);

      final participations = (rows as List)
          .map((e) => _withLocalFrame(Participation.fromJson(Map<String, dynamic>.from(e as Map))))
          .toList();

      if (cacheKey != null) {
        await _cache.write(cacheKey, rows, ttl: CacheKeys.myParticipationsTtl);
      }

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
      return Result.success(
        _withLocalFrame(Participation.fromJson(Map<String, dynamic>.from(row))),
      );
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  /// Scoped, single-row equivalent of [getMyParticipations] (same
  /// `giveaways`/`winners` join, so giveaway status and "did I win" both
  /// come back fresh) -- used by My Giveaways' realtime handlers to
  /// re-confirm exactly one participation from the server instead of a full
  /// list reload. Deliberately never trusts a realtime payload's own claim
  /// about a win; this is what actually re-asks the server, which stays the
  /// source of truth even if a `notifications` row arrives first.
  Future<Result<Participation?>> getMyParticipationWithStatusForGiveaway(String giveawayId) async {
    try {
      final row = await _client
          .from('participations')
          .select('*, giveaways(*), winners(id)')
          .eq('giveaway_id', giveawayId)
          .maybeSingle();

      if (row == null) return const Result.success(null);
      return Result.success(
        _withLocalFrame(Participation.fromJson(Map<String, dynamic>.from(row))),
      );
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  /// Patches just the embedded `giveaway` map for ONE cached participation
  /// (e.g. a status change) without touching any other cached entry -- the
  /// cache stores the raw joined rows [getMyParticipations] wrote, so this
  /// replaces only the matching row's nested `giveaways` object in place.
  Future<void> patchCachedParticipationGiveaway(
    String participationId,
    Map<String, dynamic> giveawayRecord,
  ) async {
    final cacheKey = _myParticipationsCacheKey;
    if (cacheKey == null) return;
    final cachedRows = _cache.read<List<Map<String, dynamic>>>(
      cacheKey,
      (json) => (json as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    );
    if (cachedRows == null) return;

    final index = cachedRows.indexWhere((row) => row['id'] == participationId);
    if (index == -1) return;
    final next = List<Map<String, dynamic>>.of(cachedRows);
    next[index] = {...next[index], 'giveaways': giveawayRecord};
    await _cache.write(cacheKey, next, ttl: CacheKeys.myParticipationsTtl);
  }

  /// Records that the device has seen its participation number (the
  /// `scratch_revealed_at` column predates the number-reveal redesign but
  /// still means exactly the same thing: "the user has seen this number" --
  /// kept as-is rather than renaming the column for no functional reason).
  Future<Result<void>> markNumberRevealed(String participationId) async {
    try {
      await _client
          .from('participations')
          .update({'scratch_revealed_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', participationId);
      final cacheKey = _myParticipationsCacheKey;
      if (cacheKey != null) await _cache.invalidate(cacheKey);
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  /// Called once the winner celebration is acknowledged: at that exact
  /// moment the caller's own giveaway is known to have just transitioned to
  /// `ended` server-side, so the cached My Giveaways list (up to
  /// [CacheKeys.myParticipationsTtl] stale otherwise) would keep showing it
  /// as active/unresolved until the TTL naturally expired.
  Future<void> invalidateMyParticipations() async {
    final cacheKey = _myParticipationsCacheKey;
    if (cacheKey != null) await _cache.invalidate(cacheKey);
  }

  Failure _mapFunctionException(FunctionException e) {
    final data = e.details;
    final code = (data is Map ? data['code'] as String? : null) ?? 'server_error';
    final message = data is Map ? data['message'] as String? : e.toString();
    return failureFromEdgeFunctionCode(code, message);
  }
}
