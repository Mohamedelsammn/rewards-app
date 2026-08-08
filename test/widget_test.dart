// Smoke test: Role Selection renders both role cards without needing the
// app's async bootstrap (Supabase/Hive init), unlike pumping RewardsApp
// directly would require.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/features/role_selection/presentation/role_selection_page.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('RoleSelectionPage shows both role cards', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('ar')],
        home: RoleSelectionPage(),
      ),
    );

    expect(find.text('Continue as User'), findsOneWidget);
    expect(find.text('Continue as Admin'), findsOneWidget);
  });
}
