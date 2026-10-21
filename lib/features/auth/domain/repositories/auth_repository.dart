import '../entities/app_user.dart';
import '../entities/auth_entities.dart';

/// Authentication and session contract. Implementations persist tokens in
/// secure storage; callers never see tokens.
abstract interface class AuthRepository {
  Future<bool> hasStoredSession();

  /// Loads the signed-in user from stored tokens (refreshing if needed).
  Future<AppUser> restoreSession();

  Future<OtpSendResult> sendOtp({
    required String email,
    required OtpPurpose purpose,
    required String language,
  });

  Future<OtpVerification> verifyOtp({
    required String email,
    required OtpPurpose purpose,
    required String code,
  });

  Future<AppUser> register({
    required String email,
    required String verificationToken,
    required String password,
    required int avatarId,
    required String language,
  });

  Future<AppUser> login({required String email, required String password});

  Future<void> resetPassword({
    required String email,
    required String verificationToken,
    required String newPassword,
  });

  Future<void> changePassword({required String currentPassword, required String newPassword});

  Future<List<DeviceSession>> sessions();

  Future<void> revokeSession(String id);

  /// Revokes the current session server-side (best effort) and clears tokens.
  Future<void> logout();

  Future<void> logoutAll();

  /// Clears local tokens without a server call (session already ended).
  Future<void> clearLocalSession();
}
