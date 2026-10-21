import '../../../../core/network/api_client.dart';
import '../../../../core/utils/cursor_page.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_entities.dart';
import '../models/auth_models.dart';

typedef AuthResult = ({AppUser user, String accessToken, String refreshToken});

/// `/auth/*` and `/me` endpoints (docs/FLUTTER_INTEGRATION-5.md §4).
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._api);

  final ApiClient _api;

  Future<OtpSendResult> sendOtp(String email, OtpPurpose purpose, String language) async =>
      AuthModels.otpSend(
        await _api.post(
          '/auth/otp/send',
          auth: false,
          body: {'email': email, 'purpose': purpose.apiValue, 'language': language},
        ),
      );

  Future<OtpVerification> verifyOtp(String email, OtpPurpose purpose, String code) async =>
      AuthModels.otpVerification(
        await _api.post(
          '/auth/otp/verify',
          auth: false,
          body: {'email': email, 'purpose': purpose.apiValue, 'code': code},
        ),
      );

  Future<AuthResult> register({
    required String email,
    required String verificationToken,
    required String password,
    required int avatarId,
    required String language,
    String? deviceName,
  }) async => _authResult(
    await _api.post(
      '/auth/register',
      auth: false,
      body: {
        'email': email,
        'verificationToken': verificationToken,
        'password': password,
        'avatarId': avatarId,
        'language': language,
        'deviceName': ?deviceName,
      },
    ),
  );

  Future<AuthResult> login(String email, String password, {String? deviceName}) async =>
      _authResult(
        await _api.post(
          '/auth/login',
          auth: false,
          body: {'email': email, 'password': password, 'deviceName': ?deviceName},
        ),
      );

  Future<void> resetPassword(String email, String verificationToken, String newPassword) =>
      _api.post(
        '/auth/password/reset',
        auth: false,
        body: {'email': email, 'verificationToken': verificationToken, 'newPassword': newPassword},
      );

  Future<void> changePassword(String currentPassword, String newPassword) => _api.post(
    '/auth/password/change',
    body: {'currentPassword': currentPassword, 'newPassword': newPassword},
  );

  Future<List<DeviceSession>> sessions() async =>
      parseList((await _api.get('/auth/sessions'))['items'], AuthModels.session);

  Future<void> revokeSession(String id) => _api.delete('/auth/sessions/$id');

  Future<void> logout() => _api.post('/auth/logout');

  Future<void> logoutAll() => _api.post('/auth/logout-all');

  Future<AppUser> me() async =>
      AuthModels.user(Map<String, dynamic>.from((await _api.get('/me'))['user'] as Map));

  AuthResult _authResult(Map<String, dynamic> json) {
    final tokens = AuthModels.tokens(json);
    return (
      user: AuthModels.user(Map<String, dynamic>.from(json['user'] as Map)),
      accessToken: tokens.access,
      refreshToken: tokens.refresh,
    );
  }
}
