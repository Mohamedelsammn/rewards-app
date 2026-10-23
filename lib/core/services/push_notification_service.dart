import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Registers this installation for push with the backend.
abstract interface class PushDeviceRegistrar {
  Future<void> register({required String? fcmToken, required String language});

  Future<void> unregister();
}

/// Firebase Cloud Messaging wrapper. Pushes are treated as hints: a tap
/// navigates, and any message refreshes the in-app inbox from the API.
/// Without a Firebase project (e.g. iOS before configuration) every method
/// is a no-op and the inbox still works.
class PushNotificationService {
  PushNotificationService(this._registrar);

  final PushDeviceRegistrar _registrar;
  final _taps = StreamController<Map<String, String>>.broadcast();
  final _received = StreamController<void>.broadcast();
  final _subscriptions = <StreamSubscription<Object?>>[];
  StreamSubscription<String>? _tokenRefresh;
  Map<String, String>? _initialTap;

  /// Data payloads of notifications the user tapped.
  Stream<Map<String, String>> get taps => _taps.stream;

  /// Fires when a push arrives while the app is in the foreground.
  Stream<void> get received => _received.stream;

  bool get _available => Firebase.apps.isNotEmpty;

  /// Bounded and failure-safe: push is optional and must never hold up
  /// startup (it runs before runApp).
  Future<void> initialize({Duration timeout = const Duration(seconds: 3)}) async {
    if (!_available) return;
    try {
      final messaging = FirebaseMessaging.instance;
      _subscriptions
        ..add(FirebaseMessaging.onMessageOpenedApp.listen((message) => _taps.add(_data(message))))
        ..add(FirebaseMessaging.onMessage.listen((_) => _received.add(null)));
      final initial = await messaging.getInitialMessage().timeout(timeout, onTimeout: () => null);
      if (initial != null) _initialTap = _data(initial);
    } catch (error) {
      debugPrint('Push initialization skipped: ${error.runtimeType}');
    }
  }

  /// The tap that launched the app, delivered once after sign-in.
  Map<String, String>? takeInitialTap() {
    final tap = _initialTap;
    _initialTap = null;
    return tap;
  }

  Future<void> registerForSignedInUser(String language) async {
    if (!_available) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      await _registrar.register(fcmToken: token, language: language);
      await _tokenRefresh?.cancel();
      _tokenRefresh = messaging.onTokenRefresh.listen(
        (token) => _registrar.register(fcmToken: token, language: language).ignore(),
      );
    } catch (error) {
      // Push is an enhancement; registration failures never block the app.
      debugPrint('Push registration skipped: ${error.runtimeType}');
    }
  }

  /// Must run **before** `POST /auth/logout` (the call needs the session).
  Future<void> unregister() async {
    await _tokenRefresh?.cancel();
    _tokenRefresh = null;
    if (!_available) return;
    try {
      await _registrar.unregister();
    } catch (_) {
      // Best effort: the server also drops tokens of revoked sessions.
    }
  }

  Map<String, String> _data(RemoteMessage message) => {
    for (final entry in message.data.entries) entry.key: '${entry.value}',
  };

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _tokenRefresh?.cancel();
    await _taps.close();
    await _received.close();
  }
}
