import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import '../core/config/environment.dart';
import '../core/services/ads/ads_launch_store.dart';
import '../core/services/ads/ads_manager.dart';
import '../core/services/push_notification_service.dart';
import '../features/app_config/presentation/app_config_cubit.dart';
import '../features/auth/presentation/bloc/session_cubit.dart';
import '../firebase_options.dart';
import 'app.dart';
import 'router/app_router.dart';
import 'router/routes.dart';
import 'startup/startup_ads.dart';
import 'di/injection_container.dart';

/// Background pushes are shown by the system; the inbox reloads from the API
/// when the app opens, so nothing is processed here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Push is an enhancement: the app works without Firebase (e.g. platforms
  // without a configuration in firebase_options.dart).
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (_) {}

  await configureDependencies(apiBaseUrl: Environment.apiBaseUrl);
  await sl<PushNotificationService>().initialize();

  // Both run while the splash is visible; the router reacts to each.
  final config = sl<AppConfigCubit>()..load();
  final session = sl<SessionCubit>()..restore();

  final ads = sl<AdsManager>()..attach();
  unawaited(
    StartupAdCoordinator(
      appOpen: ads.appOpen,
      launches: sl<AdsLaunchStore>(),
      warmUp: ads.warmUp,
      destination: () => switch (resolveRedirect(
        location: Routes.splash,
        config: config.state,
        updateRequired: config.updateRequired,
        session: session.state,
      )) {
        Routes.home => true,
        null => null,
        _ => false,
      },
      changes: [config.stream, session.stream],
    ).run(),
  );

  runApp(const CreativeRewardsApp());
}
