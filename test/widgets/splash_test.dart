import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/app/startup/animated_splash.dart';
import 'package:rewardsapp/core/localization/l10n.dart';
import 'package:rewardsapp/core/localization/locale_controller.dart';
import 'package:rewardsapp/core/theme/app_colors.dart';
import 'package:rewardsapp/core/theme/app_theme.dart';

Widget _app({bool reduceMotion = false}) => MaterialApp(
  theme: AppTheme.light,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: kSupportedLocales,
  home: MediaQuery(
    data: MediaQueryData(size: const Size(411, 914), disableAnimations: reduceMotion),
    child: const AnimatedSplash(),
  ),
);

Finder get _background => find.byWidgetPredicate(
  (w) => w is DecoratedBox && (w.decoration as BoxDecoration?)?.gradient == AppGradients.splash,
);

void main() {
  setUp(() => splashIntroDone.value = false);

  testWidgets('splash background fills the screen and the intro opens the gate', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    expect(tester.getSize(_background).width, tester.view.physicalSize.width / 2.625);
    expect(splashIntroDone.value, isFalse);
    // The intro starts once the first frame is on screen.
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(splashIntroDone.value, isFalse);
    await tester.pump(const Duration(milliseconds: 800));
    expect(splashIntroDone.value, isTrue);
    expect(find.text('Play · Earn · Redeem'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion shows the final frame and opens the gate at once', (tester) async {
    await tester.pumpWidget(_app(reduceMotion: true));
    expect(splashIntroDone.value, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
