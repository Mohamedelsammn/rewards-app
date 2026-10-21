import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'core/di/injection.dart';
import 'core/localization/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/splash_page.dart';
import 'firebase_options.dart';
import 'l10n/generated/app_localizations.dart';
import 'services/notification_service.dart';
import 'services/ads/ad_service.dart';
import 'redesign/demo_repository.dart';
import 'redesign/redesign_app.dart';
import 'services/secure_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The redesigned user experience is an isolated, persistent local demo.
  // No production backend is initialized or contacted in this mode.
  const dataMode = String.fromEnvironment('DATA_MODE', defaultValue: 'demo');
  if (kReleaseMode && dataMode != 'api') {
    runApp(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Release requires the production API mode.'))),
      ),
    );
    return;
  }
  // In debug builds, a missing or misspelled mode stays in the isolated demo.
  // The old integration can still be opened explicitly for maintenance.
  if (dataMode == 'demo' || (dataMode != 'api' && dataMode != 'legacy')) {
    final repository = await LocalRewardsRepository.open();
    final localeStorage = SecureStorageService();
    final locale = LocaleController(localeStorage);
    await locale.loadPersisted();
    if (await localeStorage.cachedLanguageCode == null) {
      await locale.setLocale(const Locale('en'));
    }
    runApp(RedesignApp(repository: repository, localeController: locale));
    return;
  }

  // The VPS contract is not available yet. API mode must not silently use
  // the legacy Supabase user backend or accept demo credentials.
  if (dataMode == 'api') {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Creative Rewards is unavailable until the new service is connected.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  // Both must complete before runApp() -- configureDependencies() registers
  // the services SplashPage's first build synchronously reads via getIt(),
  // and LiquidGlassWidgets.initialize() must run before runApp() by its own
  // documented contract (its Android GL shader warm-up needs to happen
  // behind the native launch screen to avoid a first-frame ANR risk). They
  // are otherwise unrelated (DI/Supabase/Hive vs. shader precompilation), so
  // running them concurrently rather than sequentially shortens the window
  // before the Flutter splash can appear without skipping anything.
  await Future.wait([configureDependencies(), LiquidGlassWidgets.initialize()]);

  // Best-effort: no real Firebase project is configured in this environment
  // (no `flutterfire configure` output, no google-services.json /
  // GoogleService-Info.plist). Firebase.initializeApp() throws without one
  // of those, so it's caught and the app continues fully functional without
  // push notifications -- see NotificationService's doc comment for the
  // activation steps once a real project exists.
  try {
    // DefaultFirebaseOptions.currentPlatform throws UnsupportedError on any
    // platform that isn't configured yet (see firebase_options.dart) --
    // caught below the same as a missing native config file would be, so
    // this degrades gracefully everywhere except Android, where real
    // Firebase project rewards-app-87115 is now wired up.
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
          navigatorObservers: getIt.isRegistered<AdNavigationObserver>()
              ? [getIt<AdNavigationObserver>()]
              : const [],
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
