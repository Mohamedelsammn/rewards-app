import 'package:flutter/widgets.dart';

import '../error/app_exception.dart';
import 'l10n.dart';

/// Localized, user-facing text for an error. API messages are English and
/// only for logs, so the app always localizes by the stable [AppException.code].
String errorMessage(BuildContext context, Object error) {
  final l10n = context.l10n;
  if (error is! AppException) return l10n.errUnknown;
  final retry = error.retryAfterSeconds;
  return switch (error.code) {
    AppException.network => l10n.errNetwork,
    AppException.timeout => l10n.errTimeout,
    'INVALID_CREDENTIALS' => l10n.errInvalidCredentials,
    'UNAUTHENTICATED' || 'TOKEN_EXPIRED' || 'INVALID_REFRESH_TOKEN' => l10n.errSessionExpired,
    'ACCOUNT_SUSPENDED' => l10n.errAccountSuspended,
    'FEATURE_DISABLED' => l10n.errFeatureDisabled,
    'NOT_FOUND' => l10n.errNotFound,
    'EMAIL_TAKEN' => l10n.errEmailTaken,
    'INSUFFICIENT_POINTS' => l10n.errInsufficientPoints,
    'OUT_OF_STOCK' => l10n.errOutOfStock,
    'PRICE_CHANGED' => l10n.errPriceChanged,
    'INVALID_TRANSITION' => l10n.errInvalidTransition,
    'PREVIOUS_ATTEMPT_UNCERTAIN' => l10n.errPreviousAttemptUncertain,
    'IDEMPOTENCY_KEY_REUSED' ||
    'REQUEST_IN_PROGRESS' ||
    'IDEMPOTENCY_KEY_REQUIRED' => l10n.errRequestInProgress,
    'GIVEAWAY_NOT_STARTED' => l10n.errGiveawayNotStarted,
    'GIVEAWAY_ENDED' => l10n.errGiveawayEnded,
    'GIVEAWAY_NOT_ACTIVE' => l10n.errGiveawayNotActive,
    'GIVEAWAY_FULL' => l10n.errGiveawayFull,
    'STEPS_INCOMPLETE' => l10n.errStepsIncomplete,
    'CLAIM_NOT_ALLOWED' => l10n.errClaimNotAllowed,
    'VALIDATION_FAILED' || 'INVALID_JSON' => l10n.errValidation,
    'OTP_INVALID' => l10n.errOtpInvalid,
    'OTP_EXPIRED' => l10n.errOtpExpired,
    'OTP_ATTEMPTS_EXCEEDED' => l10n.errOtpAttemptsExceeded,
    'OTP_VERIFICATION_INVALID' => l10n.errOtpVerificationInvalid,
    'OTP_RESEND_COOLDOWN' => l10n.errOtpResendCooldown(retry ?? 60),
    'OTP_SEND_LIMIT' => l10n.errOtpSendLimit,
    'OTP_LOCKED' => l10n.errOtpLocked,
    'EMAIL_NOT_CONFIGURED' => l10n.errEmailNotConfigured,
    'INVALID_PASSWORD' => l10n.errInvalidPassword,
    'INVALID_AVATAR' => l10n.errInvalidAvatar,
    'PROOF_REQUIRED' => l10n.errProofRequired,
    'RATE_LIMITED' => l10n.errRateLimited,
    'DAILY_LIMIT_REACHED' => l10n.errDailyLimit,
    'DEVICE_LIMIT_REACHED' => l10n.errDeviceLimit,
    'COOLDOWN' => l10n.errCooldown(retry ?? 0),
    'TOO_MANY_PENDING' => l10n.errTooManyPending,
    'SESSION_NOT_FOUND' => l10n.errAdSessionNotFound,
    'SESSION_NOT_OWNED' => l10n.errAdSessionNotOwned,
    'SESSION_EXPIRED' => l10n.earnExpired,
    'ACCOUNT_INACTIVE' => l10n.errAccountInactive,
    'AD_UNIT_NOT_ALLOWED' => l10n.errAdUnitNotAllowed,
    'NUMBER_ALLOCATION_FAILED' => l10n.errNumberAllocation,
    'INVALID_CURSOR' => l10n.errInvalidCursor,
    _ => l10n.errServer,
  };
}
