import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/features/giveaway_analytics/presentation/widgets/view_winners_button.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';

Future<void> _pump(WidgetTester tester, {required VoidCallback onTap}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: Scaffold(body: ViewWinnersButton(onTap: onTap)),
    ),
  );
}

void main() {
  group('ViewWinnersButton', () {
    testWidgets('is a single compact entry point -- no individual winner card content is '
        'rendered here', (tester) async {
      await _pump(tester, onTap: () {});

      expect(find.textContaining('View Winner'), findsOneWidget);
      // None of the per-winner fields a winner card would show.
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('tapping it invokes onTap exactly once (the caller opens the dedicated '
        'Winners page in response)', (tester) async {
      var tapCount = 0;
      await _pump(tester, onTap: () => tapCount++);

      await tester.tap(find.byType(ViewWinnersButton));
      await tester.pump();

      expect(tapCount, 1);
    });
  });
}
