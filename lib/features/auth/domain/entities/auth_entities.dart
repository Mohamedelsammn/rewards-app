import 'package:equatable/equatable.dart';

enum OtpPurpose {
  register('REGISTER'),
  forgotPassword('FORGOT_PASSWORD');

  const OtpPurpose(this.apiValue);

  final String apiValue;
}

/// `202 { sent, expiresIn, resendAfter }` from `POST /auth/otp/send`.
class OtpSendResult extends Equatable {
  const OtpSendResult({this.expiresIn = 600, this.resendAfter = 60});

  final int expiresIn;
  final int resendAfter;

  @override
  List<Object?> get props => [expiresIn, resendAfter];
}

/// Single-use proof of email ownership from `POST /auth/otp/verify`.
class OtpVerification extends Equatable {
  const OtpVerification({required this.verificationToken, this.expiresIn = 1800});

  final String verificationToken;
  final int expiresIn;

  @override
  List<Object?> get props => [verificationToken, expiresIn];
}

class DeviceSession extends Equatable {
  const DeviceSession({
    required this.id,
    required this.current,
    this.deviceName,
    this.userAgent,
    this.createdAt,
    this.lastUsedAt,
  });

  final String id;
  final String? deviceName;
  final String? userAgent;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;
  final bool current;

  @override
  List<Object?> get props => [id, deviceName, userAgent, createdAt, lastUsedAt, current];
}
