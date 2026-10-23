import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/core/error/app_exception.dart';
import 'package:rewardsapp/core/localization/error_messages.dart';
import 'package:rewardsapp/core/localization/l10n.dart';

/// Every FLUTTER_ADS-1 error code has its own message in both languages
/// (never the generic server error).
void main() {
  const codes = [
    'FEATURE_DISABLED',
    'COOLDOWN',
    'DAILY_LIMIT_REACHED',
    'DEVICE_LIMIT_REACHED',
    'TOO_MANY_PENDING',
    'SESSION_NOT_FOUND',
    'SESSION_NOT_OWNED',
    'SESSION_EXPIRED',
    'ACCOUNT_INACTIVE',
    'AD_UNIT_NOT_ALLOWED',
  ];

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('ad reward errors are localized (${locale.languageCode})', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      final l10n = AppLocalizations.of(context);
      final messages = {
        for (final code in codes)
          code: errorMessage(context, AppException(code: code, details: const {'retryAfter': 87})),
      };
      for (final entry in messages.entries) {
        expect(entry.value, isNot(l10n.errServer), reason: entry.key);
        expect(entry.value.trim(), isNotEmpty, reason: entry.key);
      }
      expect(messages['COOLDOWN'], contains('87'));
      if (locale.languageCode == 'ar') {
        expect(messages['SESSION_NOT_OWNED'], 'هذه المكافأة تخص حسابًا آخر.');
      } else {
        expect(messages['SESSION_NOT_OWNED'], 'This reward belongs to another account.');
      }
    });
  }
}
