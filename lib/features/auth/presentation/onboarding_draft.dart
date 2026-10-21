import '../domain/entities/auth_entities.dart';

/// In-memory data carried between onboarding steps. Never persisted; the
/// password exists only until the account is created.
class OnboardingDraft {
  const OnboardingDraft({
    required this.email,
    required this.purpose,
    this.resendAfter = 60,
    this.verificationToken,
    this.password,
  });

  final String email;
  final OtpPurpose purpose;
  final int resendAfter;
  final String? verificationToken;
  final String? password;

  bool get isReset => purpose == OtpPurpose.forgotPassword;

  OnboardingDraft copyWith({int? resendAfter, String? verificationToken, String? password}) =>
      OnboardingDraft(
        email: email,
        purpose: purpose,
        resendAfter: resendAfter ?? this.resendAfter,
        verificationToken: verificationToken ?? this.verificationToken,
        password: password ?? this.password,
      );
}
