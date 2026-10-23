import 'package:flutter/widgets.dart';

import '../../constants/app_constants.dart';
import '../ad_diagnostics.dart';
import 'app_open_ad_manager.dart';
import 'fullscreen_ad.dart';
import 'fullscreen_ad_gate.dart';
import 'giveaway_interstitial_pacer.dart';

/// Central AdMob coordination: one [FullscreenAdGate] shared by every
/// fullscreen format (the rewarded flows use it too), the App Open and
/// Interstitial placements, SDK/consent warm-up and the app lifecycle.
class AdsManager {
  AdsManager({
    required this.gate,
    required FullscreenAdLoader loader,
    required this._initializeSdk,
    String appOpenUnit = AdUnits.appOpen,
    String interstitialUnit = AdUnits.interstitial,
    AppOpenPolicy appOpenPolicy = const AppOpenPolicy(),
  }) : appOpen = AppOpenAdManager(
         slot: PreloadedAdSlot(
           format: FullscreenAdFormat.appOpen,
           adUnitId: appOpenUnit,
           loader: loader,
           maxAge: const Duration(hours: 4),
         ),
         gate: gate,
         policy: appOpenPolicy,
       ),
       giveaways = GiveawayInterstitialPacer(
         slot: PreloadedAdSlot(
           format: FullscreenAdFormat.interstitial,
           adUnitId: interstitialUnit,
           loader: loader,
           maxAge: const Duration(hours: 1),
         ),
         gate: gate,
       );

  final FullscreenAdGate gate;
  final AppOpenAdManager appOpen;
  final GiveawayInterstitialPacer giveaways;
  final Future<void> Function() _initializeSdk;

  /// Whether the current screen may show an App Open ad on return from the
  /// background (signed in, on a main tab). Set by the app.
  bool Function() eligibleForAppOpen = () => false;

  Future<void>? _warmUp;
  AppLifecycleListener? _lifecycle;

  /// Initializes the SDK (with the UMP consent flow) and preloads both
  /// automatic formats. Safe to call repeatedly.
  Future<void> warmUp() => _warmUp ??= _doWarmUp();

  Future<void> _doWarmUp() async {
    try {
      await _initializeSdk();
    } catch (error) {
      adLog('SDK initialization failed ${error.runtimeType}');
      _warmUp = null;
      return;
    }
    appOpen.preload();
    giveaways.preload();
  }

  /// Starts following the app lifecycle (App Open on return).
  void attach() {
    _lifecycle ??= AppLifecycleListener(
      onStateChange: (state) => appOpen.onLifecycle(state, eligibleScreen: eligibleForAppOpen()),
    );
  }

  void dispose() {
    _lifecycle?.dispose();
    _lifecycle = null;
    appOpen.dispose();
    giveaways.dispose();
  }
}
