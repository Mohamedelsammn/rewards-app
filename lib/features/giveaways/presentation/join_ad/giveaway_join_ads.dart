import 'dart:async';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/ad_diagnostics.dart';
import '../../../../core/services/admob_service.dart';
import '../../domain/entities/giveaway_entities.dart';

/// Result of the "watch an ad to join" flow.
enum JoinAdOutcome {
  /// The SDK reported the reward (`onUserEarnedReward`); joining may
  /// proceed with the existing entry API.
  rewardEarned,

  /// The ad was closed before the reward.
  skipped,

  /// No ad to show right now (no fill, consent, unsupported platform).
  unavailable,

  /// The ad failed to show, or another fullscreen ad was up.
  failed,
}

/// `ADS_JOIN_GIVEAWAY` (off by default) is the kill switch of the flow. The
/// ad unit is the shared rewarded unit (AdUnits.joinGiveawayRewarded): the
/// Google test unit in debug builds, the production unit in release.
class JoinAdFlags {
  const JoinAdFlags._();

  // Off by default: a rewarded ad must never be the price of a giveaway entry
  // with a real prize (AdMob rewarded-ad policy). Joining is free without ads.
  static const feature = bool.fromEnvironment('ADS_JOIN_GIVEAWAY', defaultValue: false);
}

typedef RewardedAdShow = Future<RewardedAdOutcome> Function({required String adUnitId});

/// "Watch an ad to join" for giveaways. When [requiresAd] is true the page
/// asks for consent, runs [watch], and only on [JoinAdOutcome.rewardEarned]
/// calls the existing `POST /giveaways/:id/entries`; the server creates the
/// entry and its number. Separate from Earn Points: no wallet credit, no
/// ad-reward session.
class GiveawayJoinAds {
  GiveawayJoinAds({
    required this._show,
    this.featureEnabled = JoinAdFlags.feature,
    this.adUnitId = AdUnits.joinGiveawayRewarded,
    this.timeout = const Duration(minutes: 6),
  });

  final RewardedAdShow _show;
  final bool featureEnabled;
  final String adUnitId;

  /// Last-resort bound of the whole ad step, so Join never stays busy.
  final Duration timeout;

  bool _running = false;

  /// Active giveaways need a rewarded view before joining whenever the flow
  /// is on and a join ad unit is configured.
  bool requiresAd(Giveaway giveaway) => featureEnabled && adUnitId.isNotEmpty && giveaway.isActive;

  /// Shows the rewarded ad (after the user consented). Only the reward
  /// callback counts; closing the ad early is [JoinAdOutcome.skipped]. A
  /// second call while one runs is refused.
  Future<JoinAdOutcome> watch(Giveaway giveaway) async {
    if (!requiresAd(giveaway)) return JoinAdOutcome.unavailable;
    if (_running) return JoinAdOutcome.failed;
    _running = true;
    try {
      // `completed` means `onUserEarnedReward` fired before dismissal.
      final outcome = await _show(
        adUnitId: adUnitId,
      ).timeout(timeout, onTimeout: () => RewardedAdOutcome.failedToShow);
      adLog('join ad: giveaway=${giveaway.id} outcome=${outcome.name}');
      return switch (outcome) {
        RewardedAdOutcome.completed => JoinAdOutcome.rewardEarned,
        RewardedAdOutcome.dismissedEarly => JoinAdOutcome.skipped,
        RewardedAdOutcome.failedToLoad ||
        RewardedAdOutcome.unsupported => JoinAdOutcome.unavailable,
        RewardedAdOutcome.failedToShow => JoinAdOutcome.failed,
      };
    } finally {
      _running = false;
    }
  }
}
