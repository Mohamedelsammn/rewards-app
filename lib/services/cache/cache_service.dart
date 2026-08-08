import 'package:hive_flutter/hive_flutter.dart';

/// TTL-wrapped key-value cache backed by Hive, sitting in front of Supabase
/// reads for anything classified as static/semi-static/user-specific (see
/// GiveawayRepository). Deliberately a simple cache-first-with-TTL policy
/// rather than full stream-based stale-while-revalidate: within the TTL
/// window, reads are served from disk with zero network calls; once expired,
/// the next read refetches and re-caches. `forceRefresh` (used by
/// pull-to-refresh) bypasses the cache outright. This keeps the caching
/// layer simple while still eliminating the vast majority of redundant
/// requests -- a full SWR-with-live-push implementation isn't justified for
/// this app's read patterns.
class CacheService {
  CacheService(this._box);

  final Box _box;

  /// Bump this whenever a cached model's `fromJson`/`toJson` shape changes
  /// incompatibly (renamed/retyped field, etc.). A version bump opens a
  /// fresh, empty box on next launch instead of the app reading old-shape
  /// JSON into new model code -- the read-path try/catch in [read] already
  /// guards against a hard crash on a shape mismatch, but a renamed field
  /// can silently parse into a *wrong* value (e.g. a dropped required field
  /// falling back to its JSON-decode default) rather than throwing, which
  /// this version prefix catches instead.
  static const _cacheVersion = 1;
  static const _boxName = 'app_cache_v$_cacheVersion';

  static Future<CacheService> initialize() async {
    await Hive.initFlutter();
    final box = await Hive.openBox(_boxName);
    return CacheService(box);
  }

  Future<void> write(String key, dynamic jsonData, {required Duration ttl}) async {
    await _box.put(key, {
      'data': jsonData,
      'cachedAtMillis': DateTime.now().millisecondsSinceEpoch,
      'ttlMillis': ttl.inMilliseconds,
    });
  }

  /// Returns the cached value if present and not expired, else null.
  T? read<T>(String key, T Function(dynamic json) fromJson) {
    final raw = _box.get(key);
    if (raw is! Map) return null;
    try {
      final cachedAtMillis = raw['cachedAtMillis'] as int;
      final ttlMillis = raw['ttlMillis'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - cachedAtMillis;
      if (age > ttlMillis) return null;
      return fromJson(raw['data']);
    } catch (_) {
      // Corrupted/incompatible cache entry -> treat as a miss, never crash.
      return null;
    }
  }

  Future<void> invalidate(String key) => _box.delete(key);

  Future<void> invalidateWhere(bool Function(String key) test) async {
    final keys = _box.keys.whereType<String>().where(test).toList();
    await _box.deleteAll(keys);
  }

  Future<void> clear() => _box.clear();
}
