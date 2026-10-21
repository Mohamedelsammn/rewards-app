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

/// AdMob rewarded ad unit. Debug, profile and explicitly marked QA release
/// builds use Google's public test unit, so real ads are never requested
/// during development.
class AdUnits {
  const AdUnits._();

  static const productionRewarded = 'ca-app-pub-6633902647647422/6209750271';
  static const _testRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const useTestAds = !kReleaseMode || bool.fromEnvironment('ADS_TEST_MODE');
  static const rewarded = useTestAds ? _testRewarded : productionRewarded;
}
