import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/core/error/failure.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';
import 'package:rewardsapp/l10n/generated/app_localizations_en.dart';

void main() {
  group('failureFromEdgeFunctionCode', () {
    test('maps already_participated to DuplicateParticipationFailure', () {
      expect(
        failureFromEdgeFunctionCode('already_participated'),
        isA<DuplicateParticipationFailure>(),
      );
    });

    test('maps giveaway_full to GiveawayFullFailure', () {
      expect(failureFromEdgeFunctionCode('giveaway_full'), isA<GiveawayFullFailure>());
    });

    test('maps giveaway_not_active and giveaway_not_found to GiveawayEndedFailure', () {
      expect(failureFromEdgeFunctionCode('giveaway_not_active'), isA<GiveawayEndedFailure>());
      expect(failureFromEdgeFunctionCode('giveaway_not_found'), isA<GiveawayEndedFailure>());
    });

    test('maps validation codes to ValidationFailure', () {
      expect(failureFromEdgeFunctionCode('invalid_phone_number'), isA<ValidationFailure>());
    });

    test('maps unauthorized/identity_not_linked to UnauthorizedFailure', () {
      expect(failureFromEdgeFunctionCode('unauthorized'), isA<UnauthorizedFailure>());
      expect(failureFromEdgeFunctionCode('identity_not_linked'), isA<UnauthorizedFailure>());
    });

    test('maps rate_limited to RateLimitedFailure', () {
      expect(failureFromEdgeFunctionCode('rate_limited'), isA<RateLimitedFailure>());
    });

    test('falls back to ServerFailure for unknown codes', () {
      expect(failureFromEdgeFunctionCode('something_unexpected'), isA<ServerFailure>());
    });
  });

  group('Failure.localize', () {
    final AppLocalizations l10n = AppLocalizationsEn();

    test('fixed-copy failures return their matching localized string', () {
      expect(const NetworkFailure().localize(l10n), l10n.failureNoInternet);
      expect(const ServerFailure().localize(l10n), l10n.failureServer);
      expect(const UnauthorizedFailure().localize(l10n), l10n.failureUnauthorized);
      expect(const DuplicatePhoneFailure().localize(l10n), l10n.failureDuplicatePhone);
      expect(
        const DuplicateParticipationFailure().localize(l10n),
        l10n.failureDuplicateParticipation,
      );
      expect(const GiveawayFullFailure().localize(l10n), l10n.failureGiveawayFull);
      expect(const GiveawayEndedFailure().localize(l10n), l10n.failureGiveawayEnded);
      expect(const RateLimitedFailure().localize(l10n), l10n.failureRateLimited);
    });

    test('ValidationFailure falls back to its raw (often server-supplied) message', () {
      const failure = ValidationFailure('Enter a valid phone number');
      expect(failure.localize(l10n), 'Enter a valid phone number');
    });
  });
}
