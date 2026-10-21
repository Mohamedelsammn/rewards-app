import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Tokens and the installation id live only in platform secure storage
/// (Keystore / Keychain). Nothing here is ever written to logs.
class SecureTokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessKey = 'api_access_token';
  static const _refreshKey = 'api_refresh_token';
  static const _installationKey = 'installation_id';
  static const _languageKey = 'cached_language_code';

  String? _cachedAccess;
  String? _cachedRefresh;
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    _cachedAccess = await _storage.read(key: _accessKey);
    _cachedRefresh = await _storage.read(key: _refreshKey);
    _loaded = true;
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

  Future<String?> get languageCode => _storage.read(key: _languageKey);

  Future<void> saveLanguageCode(String code) => _storage.write(key: _languageKey, value: code);
}
