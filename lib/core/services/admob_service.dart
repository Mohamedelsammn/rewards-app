import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/app_constants.dart';

enum RewardedAdOutcome { completed, dismissedEarly, failedToLoad, failedToShow, unsupported }

/// Shows a rewarded ad with AdMob server-side verification options.
abstract interface class RewardedAdPresenter {
  String get adUnitId;

  /// Loads the ad, applies SSV options **before** `show()`, and resolves
  /// after the ad is dismissed. The outcome is UX only: points are credited
  /// exclusively by Google's signed callback to the backend.
  Future<RewardedAdOutcome> show({required String ssvUserId, required String ssvCustomData});
}

/// AdMob SDK and UMP consent lifecycle. Initialized lazily the first time a
/// rewarded ad is needed, so users who never watch ads are not prompted.
class AdMobService implements RewardedAdPresenter {
  Future<void>? _initializing;
  bool privacyOptionsRequired = false;

  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  String get adUnitId => AdUnits.rewarded;

  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    if (!supported) return;
    await _gatherConsent();
    await MobileAds.instance.initialize();
  }

  Future<void> _gatherConsent() async {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired((_) {
        if (!done.isCompleted) done.complete();
      }),
      (_) {
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future;
    await refreshPrivacyStatus();
  }

  /// Updates [privacyOptionsRequired] for the "Ad privacy choices" row.
  Future<bool> refreshPrivacyStatus() async {
    if (!supported) return false;
    try {
      privacyOptionsRequired =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      privacyOptionsRequired = false;
    }
    return privacyOptionsRequired;
  }

  Future<void> showPrivacyOptions() async {
    if (!supported) return;
    final done = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((_) {
      if (!done.isCompleted) done.complete();
    });
    await done.future;
  }

  @override
  Future<RewardedAdOutcome> show({required String ssvUserId, required String ssvCustomData}) async {
    if (!supported) return RewardedAdOutcome.unsupported;
    await initialize();
    if (!await ConsentInformation.instance.canRequestAds()) return RewardedAdOutcome.failedToLoad;

    final loaded = Completer<RewardedAd?>();
    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(nonPersonalizedAds: true),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: loaded.complete,
        onAdFailedToLoad: (_) => loaded.complete(null),
      ),
    );
    final ad = await loaded.future;
    if (ad == null) return RewardedAdOutcome.failedToLoad;

    await ad.setServerSideOptions(
      ServerSideVerificationOptions(userId: ssvUserId, customData: ssvCustomData),
    );
    var earned = false;
    final finished = Completer<RewardedAdOutcome>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        if (!finished.isCompleted) {
          finished.complete(
            earned ? RewardedAdOutcome.completed : RewardedAdOutcome.dismissedEarly,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (failedAd, _) {
        failedAd.dispose();
        if (!finished.isCompleted) finished.complete(RewardedAdOutcome.failedToShow);
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    return finished.future;
  }
}
