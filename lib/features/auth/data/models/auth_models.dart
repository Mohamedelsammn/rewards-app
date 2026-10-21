import '../../../../core/utils/cursor_page.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_entities.dart';

/// JSON → domain mappers for `user`, `tokens` and auth responses.
class AuthModels {
  const AuthModels._();

  static AppUser user(Map<String, dynamic> json) {
    final avatar = json['avatar'];
    final stats = json['stats'];
    return AppUser(
      id: '${json['id']}',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      status: json['status'] as String? ?? 'ACTIVE',
      avatarId: avatar is Map ? (avatar['id'] as num?)?.toInt() : null,
      avatarImageUrl: avatar is Map ? avatar['imageUrl'] as String? : null,
      createdAt: parseDate(json['createdAt']),
      stats: stats is Map
          ? UserStats(
              points: parseInt(stats['points']),
              giveaways: parseInt(stats['giveaways']),
              orders: parseInt(stats['orders']),
            )
          : const UserStats(),
    );
  }

  static ({String access, String refresh}) tokens(Map<String, dynamic> json) {
    final tokens = Map<String, dynamic>.from(json['tokens'] as Map);
    return (access: tokens['accessToken'] as String, refresh: tokens['refreshToken'] as String);
  }

  static OtpSendResult otpSend(Map<String, dynamic> json) => OtpSendResult(
    expiresIn: parseInt(json['expiresIn'], 600),
    resendAfter: parseInt(json['resendAfter'], 60),
  );

  static OtpVerification otpVerification(Map<String, dynamic> json) => OtpVerification(
    verificationToken: json['verificationToken'] as String,
    expiresIn: parseInt(json['expiresIn'], 1800),
  );

  static DeviceSession session(Map<String, dynamic> json) => DeviceSession(
    id: '${json['id']}',
    deviceName: json['deviceName'] as String?,
    userAgent: json['userAgent'] as String?,
    createdAt: parseDate(json['createdAt']),
    lastUsedAt: parseDate(json['lastUsedAt']),
    current: json['current'] == true,
  );
}
