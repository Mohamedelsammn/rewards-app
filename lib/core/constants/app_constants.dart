import 'package:flutter/foundation.dart';

class AppConstants {
  const AppConstants._();

  static const androidPackage = 'com.creativehub.rewardsapp';

  /// Used when `/app-config` does not provide a `storeUrl` yet.
  static const playStoreUrl = 'https://play.google.com/store/apps/details?id=$androidPackage';

  static const requestTimeout = Duration(seconds: 15);

  /// Number of items requested per cursor page.
  static const pageSize = 20;
}

/// AdMob ad units, chosen by build mode:
/// - debug and profile builds: Google's public test units (no real ads are
///   ever requested during development);
/// - release builds: the production units below (AdMob app
///   `ca-app-pub-1922252697897939~1512836641`, see AndroidManifest.xml).
///
/// A separately identified internal test build can still opt into the test
/// units with `--dart-define=INTERNAL_TEST_ADS=true`. The former
/// `ADS_TEST_MODE` flag has no effect any more, so it cannot switch a
/// production release to test ads by accident.
///
/// The production banner unit (`ca-app-pub-1922252697897939/2985700416`) is
/// not wired: the app has no banner placements.
class AdUnits {
  const AdUnits._();

  static const productionAppOpen = 'ca-app-pub-1922252697897939/5803435443';
  static const productionInterstitial = 'ca-app-pub-1922252697897939/4085572829';

  /// Shared by Earn Points and Join Giveaway (allowed by the backend for
  /// Earn Points sessions).
  static const productionRewarded = 'ca-app-pub-1922252697897939/6382019944';

  static const _testRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const _testAppOpen = 'ca-app-pub-3940256099942544/9257395921';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';

  static const internalTestBuild = bool.fromEnvironment('INTERNAL_TEST_ADS');
  static const useTestAds = !kReleaseMode || internalTestBuild;

  static const rewarded = useTestAds ? _testRewarded : productionRewarded;
  static const appOpen = useTestAds ? _testAppOpen : productionAppOpen;
  static const interstitial = useTestAds ? _testInterstitial : productionInterstitial;
  static const joinGiveawayRewarded = rewarded;
}
