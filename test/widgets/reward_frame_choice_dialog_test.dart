import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/features/participation/presentation/pages/participation_flow_page.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';

void main() {
  Widget harness(Locale locale, {required VoidCallback onClose, required VoidCallback onWatch}) =>
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Center(
            child: RewardFrameChoiceDialog(onClose: onClose, onWatch: onWatch),
          ),
        ),
      );

  testWidgets('Arabic text and Watch Ad render in RTL without extra dialog copy', (tester) async {
    await tester.pumpWidget(harness(const Locale('ar'), onClose: () {}, onWatch: () {}));
    expect(
      find.text(
        '\u0627\u062c\u0639\u0644 \u0645\u0634\u0627\u0631\u0643\u062a\u0643 \u0645\u0645\u064a\u0632\u0629!',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        '\u0634\u0627\u0647\u062f \u0625\u0639\u0644\u0627\u0646\u064b\u0627 \u0648\u0627\u062d\u0635\u0644 \u0639\u0644\u0649 \u0625\u0637\u0627\u0631 \u0645\u0645\u064a\u0632 \u0644\u0631\u0642\u0645 \u0645\u0634\u0627\u0631\u0643\u062a\u0643 \u062f\u0627\u062e\u0644 \u0627\u0644\u062a\u0637\u0628\u064a\u0642.',
      ),
      findsOneWidget,
    );
    expect(find.text('Watch Ad'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('Watch Ad'))), TextDirection.rtl);
    expect(find.textContaining('Continue'), findsNothing);
    expect(find.textContaining('optional'), findsNothing);
  });

  testWidgets('English copy and close/watch actions are available', (tester) async {
    var closed = 0;
    var watched = 0;
    await tester.pumpWidget(
      harness(const Locale('en'), onClose: () => closed++, onWatch: () => watched++),
    );
    expect(find.text('Make your entry special!'), findsOneWidget);
    expect(
      find.text('Watch an ad to get a special frame around your participation number in the app.'),
      findsOneWidget,
    );
    expect(Directionality.of(tester.element(find.text('Watch Ad'))), TextDirection.ltr);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.tap(find.text('Watch Ad'));
    expect(closed, 1);
    expect(watched, 1);
  });
}
