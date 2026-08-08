import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'core/di/injection.dart';
import 'core/localization/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/splash_page.dart';
import 'l10n/generated/app_localizations.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();
  await LiquidGlassWidgets.initialize();

  // Best-effort: no real Firebase project is configured in this environment
  // (no `flutterfire configure` output, no google-services.json /
  // GoogleService-Info.plist). Firebase.initializeApp() throws without one
  // of those, so it's caught and the app continues fully functional without
  // push notifications -- see NotificationService's doc comment for the
  // activation steps once a real project exists.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await getIt<NotificationService>().initialize();
  } catch (_) {
    // Degrade gracefully -- push notifications are an enhancement, not a
    // hard dependency for using the app.
  }

  runApp(
    LiquidGlassWidgets.wrap(brightnessResolver: Theme.maybeBrightnessOf, child: const RewardsApp()),
  );
}

class RewardsApp extends StatelessWidget {
  const RewardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: getIt<LocaleController>(),
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Reward Giveaway',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: locale,
          supportedLocales: kSupportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashPage(),
        );
      },
    );
  }
}
