import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rewardsapp/services/cache/cache_service.dart';

void main() {
  late Directory tempDir;
  late Box box;
  late CacheService cache;

  setUp(() async {
    // Plain Hive.init (not Hive.initFlutter, which needs path_provider's
    // platform channel) pointed at a throwaway temp directory -- enough to
    // exercise CacheService's read/write/TTL/invalidate logic without any
    // Flutter engine dependency.
    tempDir = await Directory.systemTemp.createTemp('cache_service_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('test_cache');
    cache = CacheService(box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('read returns null for a key that was never written', () {
    expect(cache.read<String>('missing', (json) => json as String), isNull);
  });

  test('write then read within the TTL returns the cached value', () async {
    await cache.write('key', {'a': 1}, ttl: const Duration(minutes: 5));
    final result = cache.read<Map>('key', (json) => json as Map);
    expect(result, {'a': 1});
  });

  test('read returns null once the TTL has elapsed', () async {
    // Zero-duration TTL: the very next read is already "expired" since age
    // (however small) is never < 0.
    await cache.write('key', 'value', ttl: Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(cache.read<String>('key', (json) => json as String), isNull);
  });

  test('invalidate removes a single key without touching others', () async {
    await cache.write('a', 'valueA', ttl: const Duration(minutes: 5));
    await cache.write('b', 'valueB', ttl: const Duration(minutes: 5));

    await cache.invalidate('a');

    expect(cache.read<String>('a', (json) => json as String), isNull);
    expect(cache.read<String>('b', (json) => json as String), 'valueB');
  });

  test('invalidateWhere removes only keys matching the predicate', () async {
    await cache.write('giveaway:1', 'x', ttl: const Duration(minutes: 5));
    await cache.write('giveaway:2', 'y', ttl: const Duration(minutes: 5));
    await cache.write('participations:mine', 'z', ttl: const Duration(minutes: 5));

    await cache.invalidateWhere((key) => key.startsWith('giveaway:'));

    expect(cache.read<String>('giveaway:1', (json) => json as String), isNull);
    expect(cache.read<String>('giveaway:2', (json) => json as String), isNull);
    expect(cache.read<String>('participations:mine', (json) => json as String), 'z');
  });

  test('clear empties the whole cache', () async {
    await cache.write('a', 'x', ttl: const Duration(minutes: 5));
    await cache.write('b', 'y', ttl: const Duration(minutes: 5));

    await cache.clear();

    expect(cache.read<String>('a', (json) => json as String), isNull);
    expect(cache.read<String>('b', (json) => json as String), isNull);
  });

  test('a corrupted/incompatible entry is treated as a miss, not a crash', () async {
    // Simulates a cache-versioning mismatch: old JSON shape that the
    // provided fromJson can no longer parse.
    await cache.write('key', 'not-a-map', ttl: const Duration(minutes: 5));
    final result = cache.read<Map>('key', (json) => json as Map);
    expect(result, isNull);
  });
}
