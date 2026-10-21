import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import '../core/config/environment.dart';
import '../core/services/push_notification_service.dart';
import '../features/app_config/presentation/app_config_cubit.dart';
import '../features/auth/presentation/bloc/session_cubit.dart';
import '../firebase_options.dart';
import 'app.dart';
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
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (_) {}

  await configureDependencies(apiBaseUrl: Environment.apiBaseUrl);
  await sl<PushNotificationService>().initialize();

  // Both run while the splash is visible; the router reacts to each.
  sl<AppConfigCubit>().load();
  sl<SessionCubit>().restore();

  runApp(const CreativeRewardsApp());
}
