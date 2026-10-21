import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../firebase_options.dart';
import 'secure_storage_service.dart';

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
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (_) {
    // No Firebase project configured for this platform yet -- see
    // NotificationService doc comment / firebase_options.dart. Background
    // handling is a no-op on platforms other than Android until then.
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
  NotificationService(this._client, this._secureStorage);

  final SupabaseClient _client;
  final SecureStorageService _secureStorage;

  final _tapController = StreamController<Map<String, dynamic>>.broadcast();

  /// Fires whenever the user tapped a notification (app was backgrounded or
  /// terminated) or opened the app from one. Carries the message's `data`
  /// payload (e.g. `{type: 'winner_announcement', giveawayId: '...'}') so a
  /// consumer can pick the right screen to open -- but per the class doc,
  /// that payload must only ever be used to choose *where to navigate*,
  /// never *what the payload says happened*. A `winner_announcement` tap
  /// still only triggers a fresh server-side pending-winner check; it never
  /// trusts the payload's claim that the user won.
  Stream<Map<String, dynamic>> get onNotificationTapped => _tapController.stream;

  StreamSubscription<RemoteMessage>? _openedAppSub;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<void>? _identityChangedSub;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  /// Requests permission and wires up foreground/background/terminated tap
  /// handling. Call once after `Firebase.initializeApp()` has been
  /// attempted in `main.dart`. Safe to call even when Firebase never
  /// initialized -- it just no-ops.
  ///
  /// The initial [registerDeviceToken] call here is deliberately NOT the
  /// only registration attempt: `main()` runs this before this device's
  /// identity/session is necessarily established (Splash/Role Selection's
  /// `UserIdentityService.restoreAndVerify()` -- the thing that actually
  /// restores the anonymous session and confirms a `user_devices` row
  /// exists -- hasn't run yet at this point), and on a first-time
  /// registration the `user_devices` row this needs to write into doesn't
  /// exist until registration itself completes. Both of those call
  /// [registerDeviceToken] again once they know it can actually succeed --
  /// see their own doc comments. Without those, a token fetched here with
  /// no session yet would be silently dropped and never retried until
  /// Firebase happened to rotate it on its own (`onTokenRefresh`), which
  /// can be days or weeks away.
  Future<void> initialize() async {
    if (!_firebaseReady) return;

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // Foreground messages: no in-app banner UI is wired up for this pass
      // (would need flutter_local_notifications, out of scope) -- the
      // pending-winner check on next app-home mount still catches it.
      FirebaseMessaging.onMessage.listen((_) {});

      _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _tapController.add(message.data);
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _tapController.add(initialMessage.data);
      }

      _tokenRefreshSub = messaging.onTokenRefresh.listen(_persistToken);
      _identityChangedSub = _secureStorage.identityChanged.listen((_) => registerDeviceToken());

      await registerDeviceToken();
    } catch (_) {
      // Degrade gracefully -- see class doc.
    }
  }

  /// Fetches this device's current FCM token and persists it against
  /// whatever identity is current right now. `getToken()` returns the
  /// already-obtained token instantly (no new network round trip) once one
  /// exists, so this is cheap and safe to call repeatedly -- it's the
  /// actual mechanism that keeps `user_devices.fcm_token` in sync across
  /// every point this device's identity can become newly valid: cold start
  /// once the session is confirmed (see [UserIdentityService.restoreAndVerify]),
  /// immediately after a first-time registration creates this device's
  /// `user_devices` row (see [_identityChangedSub] above), and ordinary
  /// token rotation ([_tokenRefreshSub]).
  Future<void> registerDeviceToken() async {
    if (!_firebaseReady) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint(
        'NotificationService.registerDeviceToken: getToken() returned '
        '${token == null ? 'null' : 'a token (${token.length} chars)'}.',
      );
      if (token != null) await _persistToken(token);
    } catch (_) {
      // Degrade gracefully -- see class doc.
    }
  }

  /// Best-effort write to this device's `user_devices` row. A miss here
  /// (no row yet because the user hasn't completed registration, network
  /// blip, RLS denial) is never fatal: the token is retried on the next
  /// `onTokenRefresh` fire, identity change, or [registerDeviceToken] call.
  Future<void> _persistToken(String token) async {
    final authUid = _client.auth.currentUser?.id;
    if (authUid == null) {
      debugPrint('NotificationService._persistToken: skipped, no auth.uid() yet.');
      return;
    }

    try {
      final updated = await _client
          .from('user_devices')
          .update({'fcm_token': token, 'last_seen_at': DateTime.now().toUtc().toIso8601String()})
          .eq('auth_uid', authUid)
          .select('id');
      debugPrint(
        'NotificationService._persistToken: '
        '${(updated as List).isEmpty ? 'no matching user_devices row found' : 'updated ${updated.length} row(s)'}.',
      );
    } catch (_) {
      debugPrint('NotificationService._persistToken: update threw.');
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
    await _identityChangedSub?.cancel();
    await _tapController.close();
  }
}
