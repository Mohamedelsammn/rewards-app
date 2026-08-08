import 'package:equatable/equatable.dart';

import '../../l10n/generated/app_localizations.dart';

/// Sealed-ish Failure hierarchy (implementation-plan.md §24). Repositories
/// return `Result<T>` (see result.dart) instead of throwing, and Blocs map
/// these to user-facing copy centrally so messaging stays consistent.
///
/// [message] is the English fallback (also what server-generated,
/// genuinely-dynamic text like validation details arrives as -- there is no
/// server-side i18n in this pass, so [ValidationFailure]/[ServerFailure]
/// text from the server stays English regardless of locale; this is a
/// documented, intentional limitation, not an oversight). For the fixed-copy
/// failure types, UI code should call [localize] instead of reading
/// [message] directly so the displayed text follows the active locale.
abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  /// Locale-aware copy for this failure. Subclasses with fixed, known-set
  /// copy override this; the base implementation (used by [ServerFailure]
  /// and [ValidationFailure]) falls back to the server/default [message].
  String localize(AppLocalizations l10n) => message;

  @override
  List<Object?> get props => [message, runtimeType];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);

  @override
  String localize(AppLocalizations l10n) => l10n.failureNoInternet;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong. Please try again.']);

  @override
  String localize(AppLocalizations l10n) => l10n.failureServer;
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'You are not authorized to do that.']);

  @override
  String localize(AppLocalizations l10n) => l10n.failureUnauthorized;
}

class DuplicatePhoneFailure extends Failure {
  const DuplicatePhoneFailure([super.message = 'This phone number is already registered.']);

  @override
  String localize(AppLocalizations l10n) => l10n.failureDuplicatePhone;
}

class DuplicateParticipationFailure extends Failure {
  const DuplicateParticipationFailure([super.message = "You've already joined this giveaway."]);

  @override
  String localize(AppLocalizations l10n) => l10n.failureDuplicateParticipation;
}

class GiveawayFullFailure extends Failure {
  const GiveawayFullFailure([super.message = 'This giveaway has reached its participant limit.']);

  @override
  String localize(AppLocalizations l10n) => l10n.failureGiveawayFull;
}

class GiveawayEndedFailure extends Failure {
  const GiveawayEndedFailure([super.message = 'This giveaway is no longer active.']);

  @override
  String localize(AppLocalizations l10n) => l10n.failureGiveawayEnded;
}

class RateLimitedFailure extends Failure {
  const RateLimitedFailure([
    super.message = 'Too many attempts. Please wait a moment and try again.',
  ]);

  @override
  String localize(AppLocalizations l10n) => l10n.failureRateLimited;
}

/// Maps a raw error code returned by an Edge Function's `{ code, message }`
/// body (see edge function implementations) to a typed Failure.
Failure failureFromEdgeFunctionCode(String code, [String? message]) {
  switch (code) {
    case 'unauthorized':
    case 'identity_not_linked':
      return UnauthorizedFailure(message ?? 'Please try again.');
    case 'already_participated':
      return const DuplicateParticipationFailure();
    case 'giveaway_full':
      return const GiveawayFullFailure();
    case 'giveaway_not_active':
    case 'giveaway_not_found':
      return const GiveawayEndedFailure();
    case 'invalid_phone_number':
    case 'invalid_full_name':
    case 'invalid_country_code':
    case 'invalid_body':
      return ValidationFailure(message ?? 'Please check your details and try again.');
    case 'rate_limited':
      return const RateLimitedFailure();
    default:
      return ServerFailure(message ?? 'Something went wrong. Please try again.');
  }
}
