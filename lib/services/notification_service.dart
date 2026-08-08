import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Must be a top-level function (background messages run in a separate
/// isolate with no access to app state). Firebase Messaging invokes this
/// for data/notification messages that arrive while the app is backgrounded
/// or terminated.
///
/// Deliberately does nothing with the payload itself -- per the winner
/// architecture, a push is only ever a "go check" nudge. The actual winner
/// state lives in `winners.celebration_acknowledged_at` on the server and is
/// read by [NotificationService.onNotificationTapped] -> the pending-winner
/// check, never trusted from the message payload.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {
    // No real Firebase project configured yet -- see NotificationService
    // doc comment. Background handling is a no-op until `flutterfire
    // configure` has been run.
  }
}

/// FCM device-token lifecycle + notification-tap signalling
/// (implementation-plan.md §16 / final-pass FCM requirements).
///
/// Two things this class is explicitly NOT:
/// - NOT the source of truth for "did I win" -- it never reads winner data
///   out of a push payload. [onNotificationTapped] only tells listeners
///   "the user tapped a notification, go re-check the server," exactly the
///   same server-authoritative `celebration_acknowledged_at` read that
///   already runs on every app launch (see `UserHomeShell`).
/// - NOT a hard dependency -- every method degrades to a silent no-op if no
///   real Firebase project is configured (`Firebase.apps` empty, or any
///   FCM call throws). Push notifications are an enhancement; the app must
///   remain fully usable without them, both because no real
///   `google-services.json` / `GoogleService-Info.plist` exists yet in this
///   environment, and because that's the correct posture in production too
///   (flaky push delivery must never block core flows).
///
/// To activate real push once a Firebase project exists: run
/// `flutterfire configure` (generates `lib/firebase_options.dart` and the
/// native platform config files), pass the generated options to
/// `Firebase.initializeApp` in `main.dart`, and enable Cloud Messaging in
/// the Firebase console. No other code changes are required.
class NotificationService {
  NotificationService(this._client);

  final SupabaseClient _client;

  final _tapController = StreamController<void>.broadcast();

  /// Fires whenever the user tapped a notification (app was backgrounded or
  /// terminated) or opened the app from one. Carries no payload data on
  /// purpose -- see class doc.
  Stream<void> get onNotificationTapped => _tapController.stream;

  StreamSubscription<RemoteMessage>? _openedAppSub;
  StreamSubscription<String>? _tokenRefreshSub;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  /// Requests permission, registers the current device token, and wires up
  /// foreground/background/terminated tap handling. Call once after
  /// `Firebase.initializeApp()` has been attempted in `main.dart`. Safe to
  /// call even when Firebase never initialized -- it just no-ops.
  Future<void> initialize() async {
    if (!_firebaseReady) return;

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // Foreground messages: no in-app banner UI is wired up for this pass
      // (would need flutter_local_notifications, out of scope) -- the
      // pending-winner check on next app-home mount still catches it.
      FirebaseMessaging.onMessage.listen((_) {});

      _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((_) {
        _tapController.add(null);
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _tapController.add(null);
      }

      _tokenRefreshSub = messaging.onTokenRefresh.listen(_persistToken);

      final token = await messaging.getToken();
      if (token != null) {
        await _persistToken(token);
      }
    } catch (_) {
      // Degrade gracefully -- see class doc.
    }
  }

  /// Best-effort write to this device's `user_devices` row. A miss here
  /// (no row yet because the user hasn't completed registration, network
  /// blip, RLS denial) is never fatal: the token is retried on the next
  /// `onTokenRefresh` fire or app launch.
  Future<void> _persistToken(String token) async {
    final authUid = _client.auth.currentUser?.id;
    if (authUid == null) return;

    try {
      await _client
          .from('user_devices')
          .update({'fcm_token': token, 'last_seen_at': DateTime.now().toUtc().toIso8601String()})
          .eq('auth_uid', authUid);
    } catch (_) {
      // Best-effort; see doc comment.
    }
  }

  /// Clears this device's token server-side (e.g. on sign-out) so a stale
  /// token doesn't keep receiving pushes for an identity the device no
  /// longer represents locally.
  Future<void> invalidateToken() async {
    if (!_firebaseReady) return;
    final authUid = _client.auth.currentUser?.id;
    if (authUid == null) return;

    try {
      await _client.from('user_devices').update({'fcm_token': null}).eq('auth_uid', authUid);
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Best-effort; see doc comment.
    }
  }

  Future<void> dispose() async {
    await _openedAppSub?.cancel();
    await _tokenRefreshSub?.cancel();
    await _tapController.close();
  }
}
