import 'cache/cache_service.dart';

/// Device-local cosmetic entitlement storage. A client-side rewarded callback
/// is intentionally not treated as server-verifiable proof. Keys are scoped
/// to the active Supabase auth UID and the exact giveaway/participation.
class RewardFrameEntitlementStore {
  RewardFrameEntitlementStore(this._cache, {required this.authUserId});

  final CacheService _cache;
  final String? Function() authUserId;

  static const _earnedTtl = Duration(days: 30);
  static const _entitlementTtl = Duration(days: 3650);

  String? _pendingKey(String giveawayId) {
    final userId = authUserId();
    if (userId == null || userId.isEmpty) return null;
    return 'reward_frame_pending:$userId:$giveawayId';
  }

  String? _entitlementKey(String giveawayId, String participationId) {
    final userId = authUserId();
    if (userId == null || userId.isEmpty) return null;
    return 'reward_frame:$userId:$giveawayId:$participationId';
  }

  Future<void> markEarned(String giveawayId) async {
    final key = _pendingKey(giveawayId);
    if (key == null) return;
    await _cache.write(key, true, ttl: _earnedTtl);
  }

  bool hasPending(String giveawayId) {
    final key = _pendingKey(giveawayId);
    if (key == null) return false;
    return _cache.read<bool>(key, (value) => value as bool) ?? false;
  }

  Future<void> attach(String giveawayId, String participationId) async {
    final key = _entitlementKey(giveawayId, participationId);
    if (key == null) return;
    await _cache.write(key, true, ttl: _entitlementTtl);
    final pending = _pendingKey(giveawayId);
    if (pending != null) await _cache.invalidate(pending);
  }

  bool hasEntitlement(String giveawayId, String participationId) {
    final key = _entitlementKey(giveawayId, participationId);
    if (key == null) return false;
    return _cache.read<bool>(key, (value) => value as bool) ?? false;
  }
}
