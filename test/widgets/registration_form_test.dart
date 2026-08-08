import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/features/participation/presentation/widgets/registration_form.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pumpForm(
    WidgetTester tester, {
    required void Function(String, String, String) onSubmit,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: Scaffold(
          body: SingleChildScrollView(
            child: RegistrationForm(isSubmitting: false, onSubmit: onSubmit),
          ),
        ),
      ),
    );
  }

  testWidgets('shows validation errors for empty name and empty phone', (tester) async {
    var submitted = false;
    await pumpForm(tester, onSubmit: (_, _, _) => submitted = true);

    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your full name'), findsOneWidget);
    expect(find.text('Enter your phone number'), findsOneWidget);
    expect(submitted, isFalse);
  });

  testWidgets('rejects a too-short phone number', (tester) async {
    var submitted = false;
    await pumpForm(tester, onSubmit: (_, _, _) => submitted = true);

    await tester.enterText(find.widgetWithText(TextFormField, 'Jane Doe'), 'Jane Doe');
    await tester.enterText(find.widgetWithText(TextFormField, '(555) 000-0000'), '123');
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid phone number'), findsOneWidget);
    expect(submitted, isFalse);
  });

  testWidgets('submits normalized E.164 phone on valid input', (tester) async {
    String? capturedName;
    String? capturedPhone;
    String? capturedCountry;

    await pumpForm(
      tester,
      onSubmit: (name, phone, country) {
        capturedName = name;
        capturedPhone = phone;
        capturedCountry = country;
      },
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Jane Doe'), 'Jane Doe');
    await tester.enterText(find.widgetWithText(TextFormField, '(555) 000-0000'), '2025550190');
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(capturedName, 'Jane Doe');
    expect(capturedPhone, '+12025550190');
    expect(capturedCountry, 'US');
  });
}
