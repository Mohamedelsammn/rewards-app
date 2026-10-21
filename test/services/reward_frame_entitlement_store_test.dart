import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/services/cache/cache_service.dart';
import 'package:rewardsapp/services/reward_frame_entitlement_store.dart';

class _MemoryCache extends Fake implements CacheService {
  final Map<String, Map<String, dynamic>> values = {};

  @override
  Future<void> write(String key, dynamic jsonData, {required Duration ttl}) async {
    values[key] = {'data': jsonData, 'ttlMillis': ttl.inMilliseconds};
  }

  @override
  T? read<T>(String key, T Function(dynamic json) fromJson) {
    final entry = values[key];
    if (entry == null) return null;
    try {
      return fromJson(entry['data']);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> invalidate(String key) async => values.remove(key);
}

void main() {
  late _MemoryCache cache;
  late String? activeUserId;
  late RewardFrameEntitlementStore store;

  setUp(() {
    cache = _MemoryCache();
    activeUserId = 'auth-a';
    store = RewardFrameEntitlementStore(cache, authUserId: () => activeUserId);
  });

  test('earned reward is attached to the actual participation and persisted locally', () async {
    await store.markEarned('giveaway-a');
    expect(store.hasPending('giveaway-a'), isTrue);

    await store.attach('giveaway-a', 'participation-a');

    expect(store.hasEntitlement('giveaway-a', 'participation-a'), isTrue);
    expect(store.hasPending('giveaway-a'), isFalse);
    expect(store.hasEntitlement('giveaway-a', 'participation-b'), isFalse);

    final restoredStore = RewardFrameEntitlementStore(cache, authUserId: () => activeUserId);
    expect(restoredStore.hasEntitlement('giveaway-a', 'participation-a'), isTrue);
  });

  test('entitlements are scoped to the authenticated user and giveaway', () async {
    await store.markEarned('giveaway-a');
    await store.attach('giveaway-a', 'participation-a');

    activeUserId = 'auth-b';
    expect(store.hasPending('giveaway-a'), isFalse);
    expect(store.hasEntitlement('giveaway-a', 'participation-a'), isFalse);

    activeUserId = 'auth-a';
    expect(store.hasEntitlement('giveaway-b', 'participation-a'), isFalse);
  });

  test('missing authenticated identity cannot create or read a frame entitlement', () async {
    activeUserId = null;
    await store.markEarned('giveaway-a');
    await store.attach('giveaway-a', 'participation-a');

    expect(store.hasPending('giveaway-a'), isFalse);
    expect(store.hasEntitlement('giveaway-a', 'participation-a'), isFalse);
    expect(cache.values, isEmpty);
  });
}
