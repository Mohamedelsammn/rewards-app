// Golden coverage for a high-value screen in both supported locales,
// including Arabic RTL (final-pass requirement). RoleSelectionPage is a
// good golden candidate: no async bootstrap dependency at build time (DI
// calls only happen inside onTap), so it pumps standalone like the smoke
// test in widget_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/features/role_selection/presentation/role_selection_page.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';

Future<void> _pumpRoleSelection(WidgetTester tester, Locale locale) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: const RoleSelectionPage(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('RoleSelectionPage (English, LTR) golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await _pumpRoleSelection(tester, const Locale('en'));

    expect(Directionality.of(tester.element(find.byType(RoleSelectionPage))), TextDirection.ltr);
    await expectLater(
      find.byType(RoleSelectionPage),
      matchesGoldenFile('goldens/role_selection_en.png'),
    );
  });

  testWidgets('RoleSelectionPage (Arabic, RTL) golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await _pumpRoleSelection(tester, const Locale('ar'));

    // The whole point of this second golden: confirm the locale switch
    // actually flips layout direction, not just swaps strings.
    expect(Directionality.of(tester.element(find.byType(RoleSelectionPage))), TextDirection.rtl);
    await expectLater(
      find.byType(RoleSelectionPage),
      matchesGoldenFile('goldens/role_selection_ar.png'),
    );
  });
}
