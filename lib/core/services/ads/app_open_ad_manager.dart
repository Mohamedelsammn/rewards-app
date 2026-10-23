import 'dart:ui' show AppLifecycleState;

import '../ad_diagnostics.dart';
import 'fullscreen_ad.dart';
import 'fullscreen_ad_gate.dart';

/// Frequency caps of the App Open ad.
class AppOpenPolicy {
  const AppOpenPolicy({
    this.minBackground = const Duration(seconds: 30),
    this.minGapAfterAnyAd = const Duration(minutes: 2),
    this.minGapBetweenAppOpen = const Duration(minutes: 15),
    this.startupWait = const Duration(seconds: 3),
  });

  /// Shorter trips away (a share sheet, a quick app switch) never show one.
  final Duration minBackground;

  /// Nothing right after another fullscreen ad (or returning from one).
  final Duration minGapAfterAnyAd;
  final Duration minGapBetweenAppOpen;

  /// How long the splash may wait for an App Open ad still loading.
  final Duration startupWait;
}

/// App Open ads: one on a cold start (over the splash, before Home is
/// interactive) and on returning from the background to a main tab.
/// Never on the first launch, on signed-out or onboarding screens, while
/// another fullscreen ad is up, or right after one.
class AppOpenAdManager {
  AppOpenAdManager({required this.slot, required this.gate, this.policy = const AppOpenPolicy()});

  final PreloadedAdSlot slot;
  final FullscreenAdGate gate;
  final AppOpenPolicy policy;

  DateTime? _backgroundSince;
  bool _leftFromAd = false;
  DateTime? _lastShown;

  bool get enabled => slot.enabled;

  void preload() => slot.preload();

  void dispose() => slot.dispose();

  /// Cold start, while the splash is still up. Completes when the ad is
  /// dismissed, or at once when none is ready within [AppOpenPolicy.startupWait].
  Future<bool> showOnStartup() async {
    if (!enabled || !await slot.readyWithin(policy.startupWait)) {
      adLog('appOpen startup: none ready');
      return false;
    }
    return _show('startup');
  }

  /// Feed of app lifecycle changes. Returns whether an ad was shown.
  Future<bool> onLifecycle(AppLifecycleState state, {required bool eligibleScreen}) async {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (_backgroundSince == null) {
          _backgroundSince = gate.now;
          // Leaving the app from a fullscreen ad (a click) is not a return.
          _leftFromAd = gate.showing;
        }
        return false;
      case AppLifecycleState.resumed:
        final since = _backgroundSince;
        final fromAd = _leftFromAd;
        _backgroundSince = null;
        _leftFromAd = false;
        if (since == null || fromAd || !eligibleScreen || !enabled) return false;
        if (gate.now.difference(since) < policy.minBackground) return false;
        if (!gate.allows(policy.minGapAfterAnyAd)) return false;
        final last = _lastShown;
        if (last != null && gate.now.difference(last) < policy.minGapBetweenAppOpen) return false;
        if (!slot.isReady) {
          slot.preload();
          return false;
        }
        return _show('resume');
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        return false;
    }
  }

  Future<bool> _show(String reason) async {
    final ad = slot.take();
    if (ad == null) return false;
    final shown = await showGated(gate, ad) ?? false;
    if (shown) _lastShown = gate.now;
    adLog('appOpen $reason shown=$shown');
    slot.preload();
    return shown;
  }
}
