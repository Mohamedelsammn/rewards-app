import 'package:flutter/foundation.dart';

class AdConstants {
  AdConstants._();
  static const appId = 'ca-app-pub-6633902647647422~7562449689';
  static const productionBanner = 'ca-app-pub-6633902647647422/8835913618';
  static const productionAppOpen = 'ca-app-pub-6633902647647422/7426718311';
  static const productionInterstitial = 'ca-app-pub-6633902647647422/7522831942';
  static const productionRewarded = 'ca-app-pub-6633902647647422/6209750271';
  // Profile/debug and explicitly marked release QA builds never request real ads.
  static const testAds = !kReleaseMode || bool.fromEnvironment('ADS_TEST_MODE');
  static const banner = testAds ? 'ca-app-pub-3940256099942544/6300978111' : productionBanner;
  static const appOpen = testAds ? 'ca-app-pub-3940256099942544/9257395921' : productionAppOpen;
  static const interstitial = testAds
      ? 'ca-app-pub-3940256099942544/1033173712'
      : productionInterstitial;
  static const rewarded = testAds ? 'ca-app-pub-3940256099942544/5224354917' : productionRewarded;
}
