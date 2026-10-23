import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Tokens and the installation id live only in platform secure storage
/// (Keystore / Keychain). Nothing here is ever written to logs.
class SecureTokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage]) : _storage = storage ?? secureStorage;

  /// `resetOnError`: data that can no longer be decrypted (its Keystore key
  /// is gone) is wiped by the plugin instead of failing every read.
  static const secureStorage = FlutterSecureStorage(aOptions: AndroidOptions(resetOnError: true));

  final FlutterSecureStorage _storage;

  static const _accessKey = 'api_access_token';
  static const _refreshKey = 'api_refresh_token';
  static const _installationKey = 'installation_id';
  static const _languageKey = 'cached_language_code';

  String? _cachedAccess;
  String? _cachedRefresh;
  bool _loaded = false;

  /// The stored tokens could not be read and were discarded; reported once
  /// (see [takeReadFailure]) so the user is told to sign in again.
  bool _unreportedFailure = false;

  Future<void> _load() async {
    if (_loaded) return;
    try {
      _cachedAccess = await _storage.read(key: _accessKey);
      _cachedRefresh = await _storage.read(key: _refreshKey);
    } catch (_) {
      // Unreadable storage: never retry in a loop, never keep half a session.
      // Nothing about the tokens is logged.
      _cachedAccess = null;
      _cachedRefresh = null;
      _unreportedFailure = true;
      await _quietly(() => _storage.delete(key: _accessKey));
      await _quietly(() => _storage.delete(key: _refreshKey));
    }
    _loaded = true;
  }

  /// Whether a read failure is still to be reported; clears the flag.
  bool takeReadFailure() {
    final failed = _unreportedFailure;
    _unreportedFailure = false;
    return failed;
  }

  static Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {}
  }

  Future<String?> get accessToken async {
    await _load();
    return _cachedAccess;
  }

  Future<String?> get refreshToken async {
    await _load();
    return _cachedRefresh;
  }

  Future<bool> get hasSession async => (await refreshToken) != null;

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _cachedAccess = accessToken;
    _cachedRefresh = refreshToken;
    _loaded = true;
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  /// Re-reads tokens from storage, used after `409 REFRESH_ALREADY_ROTATED`.
  Future<void> reload() async {
    _loaded = false;
    await _load();
  }

  Future<void> clearTokens() async {
    _cachedAccess = null;
    _cachedRefresh = null;
    _loaded = true;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  /// Stable per-install id, used as `deviceId` for ad rewards and as the
  /// `installationId` for push registration.
  Future<String> installationId() async {
    final existing = await _storage.read(key: _installationKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final created = const Uuid().v4();
    await _storage.write(key: _installationKey, value: created);
    return created;
  }

  /// `null` when unset or unreadable (the device language is used then).
  Future<String?> get languageCode async {
    try {
      return await _storage.read(key: _languageKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLanguageCode(String code) => _storage.write(key: _languageKey, value: code);
}
