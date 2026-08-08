import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage for the locally cached identity
/// (implementation-plan.md §17). Never treated as the security boundary --
/// that's the Supabase Auth session, persisted independently by the SDK.
/// This only avoids re-showing the registration form and enables optimistic
/// UI.
class SecureStorageService {
  SecureStorageService([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _keyUserId = 'cached_user_id';
  static const _keyFullName = 'cached_full_name';
  static const _keyLastRole = 'cached_last_role';
  static const _keyLanguageCode = 'cached_language_code';

  Future<void> saveIdentity({required String userId, required String fullName}) async {
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyFullName, value: fullName);
  }

  Future<String?> get cachedUserId => _storage.read(key: _keyUserId);
  Future<String?> get cachedFullName => _storage.read(key: _keyFullName);

  Future<void> saveLastRole(String role) => _storage.write(key: _keyLastRole, value: role);
  Future<String?> get cachedLastRole => _storage.read(key: _keyLastRole);

  Future<void> saveLanguageCode(String code) => _storage.write(key: _keyLanguageCode, value: code);
  Future<String?> get cachedLanguageCode => _storage.read(key: _keyLanguageCode);

  Future<void> clearIdentity() async {
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyFullName);
  }

  /// Used by User Sign Out: only clears the "last role" flag so Splash sends
  /// the device back to Role Selection instead of auto-skipping into User
  /// Home. Deliberately does NOT touch [cachedUserId]/[cachedFullName] --
  /// see the Sign Out cubit for why the underlying identity/session must
  /// survive.
  Future<void> clearLastRole() => _storage.delete(key: _keyLastRole);

  Future<void> clearAll() => _storage.deleteAll();
}
