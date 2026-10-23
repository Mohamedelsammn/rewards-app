import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/app_constants.dart';
import 'ad_diagnostics.dart';
import 'ads/fullscreen_ad_gate.dart';

enum RewardedAdOutcome { completed, dismissedEarly, failedToLoad, failedToShow, unsupported }

/// Shows the Earn Points rewarded ad.
abstract interface class RewardedAdPresenter {
  String get adUnitId;

  /// Loads and shows the ad; resolves after it is dismissed.
  /// [RewardedAdOutcome.completed] means `onUserEarnedReward` fired, which is
  /// the only event that allows a claim; the server still decides.
  Future<RewardedAdOutcome> show();
}

/// AdMob SDK and UMP consent lifecycle. Initialized lazily the first time a
/// rewarded ad is needed, so users who never watch ads are not prompted.
class AdMobService implements RewardedAdPresenter {
  AdMobService({FullscreenAdGate? gate}) : _gate = gate ?? FullscreenAdGate();

  /// Shared with the App Open and Interstitial placements: one fullscreen
  /// ad at a time, and App Open never right after a rewarded video.
  final FullscreenAdGate _gate;
  Future<void>? _initializing;
  bool privacyOptionsRequired = false;

  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  String get adUnitId => AdUnits.rewarded;

  /// Upper bounds for SDK callbacks that may never arrive: consent and SDK
  /// start-up, ad loading, and an ad's dismissal (a lost callback must not
  /// lock the fullscreen gate or keep a button busy forever).
  static const initTimeout = Duration(seconds: 10);
  static const loadTimeout = Duration(seconds: 30);
  static const showTimeout = Duration(minutes: 5);

  /// Never fails and never hangs: ads are optional.
  Future<void> initialize() => _initializing ??= _initialize();

  /// SDK initialized (consent gathered) and consent allows ad requests.
  Future<bool> readyForAds() async {
    if (!supported) return false;
    await initialize();
    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      return false;
    }
  }

  Future<void> _initialize() async {
    if (!supported) return;
    try {
      await _gatherConsent().timeout(initTimeout);
    } catch (error) {
      adLog('consent step skipped ${error.runtimeType}');
    }
    try {
      await MobileAds.instance.initialize().timeout(initTimeout);
    } catch (error) {
      // The SDK may still finish in the background; loads then fail softly.
      adLog('SDK initialization slow or failed ${error.runtimeType}');
    }
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
  Future<RewardedAdOutcome> show() => showRewarded(adUnitId: adUnitId);

  /// Loads and shows a rewarded ad of [adUnitId]; resolves after dismissal.
  /// [RewardedAdOutcome.completed] only when `onUserEarnedReward` fired
  /// before the ad closed (dismissal alone is never a completion).
  Future<RewardedAdOutcome> showRewarded({required String adUnitId}) async {
    if (!supported) return RewardedAdOutcome.unsupported;
    if (_gate.showing) return RewardedAdOutcome.failedToShow;
    if (!await readyForAds()) {
      adLog('consent does not allow ad requests');
      return RewardedAdOutcome.failedToLoad;
    }

    final started = DateTime.now();
    adLog('loading ad unit=$adUnitId sample=${AdUnits.useTestAds}');
    final loaded = Completer<RewardedAd?>();
    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(nonPersonalizedAds: true),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: loaded.complete,
        onAdFailedToLoad: (error) {
          adWarn(
            'rewarded load failed code=${error.code} domain=${error.domain} '
            'message=${error.message}',
          );
          loaded.complete(null);
        },
      ),
    );
    final ad = await loaded.future.timeout(
      loadTimeout,
      onTimeout: () {
        adLog('rewarded load timed out');
        // A load that completes later is released, not leaked.
        loaded.future.then((late) => late?.dispose()).ignore();
        return null;
      },
    );
    if (ad == null) return RewardedAdOutcome.failedToLoad;
    adLog(
      'loaded in ${DateTime.now().difference(started).inMilliseconds} ms '
      'adapter=${ad.responseInfo?.mediationAdapterClassName}',
    );

    var earned = false;
    final finished = Completer<RewardedAdOutcome>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shownAd) {
        adLog('dismissed earned=$earned');
        shownAd.dispose();
        if (!finished.isCompleted) {
          finished.complete(
            earned ? RewardedAdOutcome.completed : RewardedAdOutcome.dismissedEarly,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        adWarn('rewarded show failed code=${error.code} message=${error.message}');
        failedAd.dispose();
        if (!finished.isCompleted) finished.complete(RewardedAdOutcome.failedToShow);
      },
    );
    final outcome = await _gate.run(() async {
      try {
        await ad.show(
          onUserEarnedReward: (_, reward) {
            // UX only: never a credit or an authorization by itself.
            adLog('user earned reward ${reward.amount} ${reward.type}');
            earned = true;
          },
        );
      } catch (error) {
        adLog('show threw ${error.runtimeType}');
        if (!finished.isCompleted) finished.complete(RewardedAdOutcome.failedToShow);
      }
      return finished.future.timeout(
        showTimeout,
        onTimeout: () {
          // The dismissal callback never came: release the gate. Only a
          // reward reported before this point counts.
          adLog('rewarded dismissal timed out earned=$earned');
          ad.dispose();
          return earned ? RewardedAdOutcome.completed : RewardedAdOutcome.dismissedEarly;
        },
      );
    });
    if (outcome == null) ad.dispose();
    return outcome ?? RewardedAdOutcome.failedToShow;
  }
}
