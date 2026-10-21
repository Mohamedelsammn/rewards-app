import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/security/secure_token_storage.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._tokens);

  final AuthRemoteDataSource _remote;
  final SecureTokenStorage _tokens;

  String get _deviceName => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'Android',
    TargetPlatform.iOS => 'iPhone',
    _ => 'Creative Rewards',
  };

  @override
  Future<bool> hasStoredSession() => _tokens.hasSession;

  @override
  Future<AppUser> restoreSession() async {
    if (!await _tokens.hasSession) {
      throw const AppException(code: 'UNAUTHENTICATED', statusCode: 401);
    }
    return _remote.me();
  }

  @override
  Future<OtpSendResult> sendOtp({
    required String email,
    required OtpPurpose purpose,
    required String language,
  }) => _remote.sendOtp(email, purpose, language);

  @override
  Future<OtpVerification> verifyOtp({
    required String email,
    required OtpPurpose purpose,
    required String code,
  }) => _remote.verifyOtp(email, purpose, code);

  @override
  Future<AppUser> register({
    required String email,
    required String verificationToken,
    required String password,
    required int avatarId,
    required String language,
  }) async {
    final result = await _remote.register(
      email: email,
      verificationToken: verificationToken,
      password: password,
      avatarId: avatarId,
      language: language,
      deviceName: _deviceName,
    );
    await _tokens.saveTokens(accessToken: result.accessToken, refreshToken: result.refreshToken);
    return result.user;
  }

  @override
  Future<AppUser> login({required String email, required String password}) async {
    final result = await _remote.login(email, password, deviceName: _deviceName);
    await _tokens.saveTokens(accessToken: result.accessToken, refreshToken: result.refreshToken);
    return result.user;
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String verificationToken,
    required String newPassword,
  }) => _remote.resetPassword(email, verificationToken, newPassword);

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) =>
      _remote.changePassword(currentPassword, newPassword);

  @override
  Future<List<DeviceSession>> sessions() => _remote.sessions();

  @override
  Future<void> revokeSession(String id) => _remote.revokeSession(id);

  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } on AppException {
      // Signing out must always succeed locally, even offline or when the
      // session was already revoked server-side.
    } finally {
      await _tokens.clearTokens();
    }
  }

  @override
  Future<void> logoutAll() async {
    await _remote.logoutAll();
    await _tokens.clearTokens();
  }

  @override
  Future<void> clearLocalSession() => _tokens.clearTokens();
}
