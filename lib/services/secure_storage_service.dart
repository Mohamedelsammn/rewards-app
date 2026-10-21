import 'dart:async';

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
  final _identityChangedController = StreamController<void>.broadcast();

  /// Fires the moment this device's cached identity is (re)written or
  /// cleared -- e.g. a successful registration or an Edit Profile save --
  /// so a screen that was already mounted before the change (and so never
  /// re-reads on its own, e.g. Settings/Home sitting inside the User
  /// shell's IndexedStack) can refresh immediately instead of only picking
  /// it up on its next fresh mount. Mirrors the same "local,
  /// already-confirmed-success signal" pattern already used by
  /// GiveawayRepository.giveawayCreated / ParticipationRepository.
  /// participationCreated.
  Stream<void> get identityChanged => _identityChangedController.stream;

  static const _keyUserId = 'cached_user_id';
  static const _keyFullName = 'cached_full_name';
  static const _keyPhone = 'cached_phone';
  static const _keyCountryCode = 'cached_country_code';
  static const _keyLastRole = 'cached_last_role';
  static const _keyLanguageCode = 'cached_language_code';
  static const _keyAnonRefreshToken = 'cached_anon_refresh_token';

  /// [phone]/[countryCode] are optional purely for call-site convenience
  /// (older call sites that don't have them handy); registration and Edit
  /// Profile always have both in practice.
  Future<void> saveIdentity({
    required String userId,
    required String fullName,
    String? phone,
    String? countryCode,
  }) async {
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyFullName, value: fullName);
    if (phone != null) await _storage.write(key: _keyPhone, value: phone);
    if (countryCode != null) await _storage.write(key: _keyCountryCode, value: countryCode);
    _identityChangedController.add(null);
  }

  // Reads are defensive against the underlying platform channel throwing
  // (e.g. an Android Keystore key invalidated by an OS/backup event) --
  // treated as a cache miss rather than an uncaught exception that would
  // otherwise crash Splash/Role Selection on every launch.
  Future<String?> get cachedUserId => _readOrNull(_keyUserId);
  Future<String?> get cachedFullName => _readOrNull(_keyFullName);

  /// The E.164 phone number captured at registration -- displayed on the
  /// User Settings profile header once the user has registered. Purely
  /// display data, same "optimistic UI, never the security boundary" status
  /// as [cachedFullName] (see class doc comment).
  Future<String?> get cachedPhone => _readOrNull(_keyPhone);

  /// The country code captured at registration/Edit Profile -- used to
  /// pre-fill the country picker so editing a profile doesn't force the
  /// user to re-pick their country from scratch.
  Future<String?> get cachedCountryCode => _readOrNull(_keyCountryCode);

  Future<void> saveLastRole(String role) => _storage.write(key: _keyLastRole, value: role);
  Future<String?> get cachedLastRole => _readOrNull(_keyLastRole);

  Future<void> saveLanguageCode(String code) => _storage.write(key: _keyLanguageCode, value: code);
  Future<String?> get cachedLanguageCode => _readOrNull(_keyLanguageCode);

  /// A standby copy of the device's anonymous-session refresh token, kept
  /// independently of the Supabase SDK's own persisted session. GoTrue only
  /// holds one active session per client; an Admin signing in on this same
  /// device evicts the User's anonymous session, and Admin sign-out destroys
  /// it outright. Without this standby copy, the next `ensureAnonymousSession()`
  /// would mint a brand-new anonymous auth.uid() with no link to this
  /// device's existing `user_devices`/`participations` rows. See
  /// [AuthRepository] for how this is preserved and restored.
  Future<void> saveAnonymousRefreshToken(String token) =>
      _storage.write(key: _keyAnonRefreshToken, value: token);
  Future<String?> get cachedAnonymousRefreshToken => _readOrNull(_keyAnonRefreshToken);
  Future<void> clearAnonymousRefreshToken() => _storage.delete(key: _keyAnonRefreshToken);

  Future<String?> _readOrNull(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearIdentity() async {
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyFullName);
    await _storage.delete(key: _keyPhone);
    await _storage.delete(key: _keyCountryCode);
    _identityChangedController.add(null);
  }

  /// Used by User Sign Out: only clears the "last role" flag so Splash sends
  /// the device back to Role Selection instead of auto-skipping into User
  /// Home. Deliberately does NOT touch [cachedUserId]/[cachedFullName] --
  /// see the Sign Out cubit for why the underlying identity/session must
  /// survive.
  Future<void> clearLastRole() => _storage.delete(key: _keyLastRole);

  Future<void> clearAll() => _storage.deleteAll();
}
