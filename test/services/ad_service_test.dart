import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// SDK test codecs are used solely to mock native callbacks; no real ads are requested.
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ump/user_messaging_codec.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/services/ads/ad_service.dart';
import 'package:rewardsapp/services/cache/cache_service.dart';

class Cache extends Mock implements CacheService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(Duration.zero));
  late AdService ads;
  late Cache cache;
  late List<MethodCall> calls;
  var consentAllowed = true;
  Completer<void>? firstConsentGate;
  Completer<void>? sdkGate;
  var consentRequests = 0;
  final ump = MethodChannel(
    'plugins.flutter.io/google_mobile_ads/ump',
    StandardMethodCodec(UserMessagingCodec()),
  );
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Future<void> event(int id, String event, [Map<String, dynamic> extra = const {}]) async {
    await messenger.handlePlatformMessage(
      instanceManager.channel.name,
      instanceManager.channel.codec.encodeMethodCall(
        MethodCall('onAdEvent', {'adId': id, 'eventName': event, ...extra}),
      ),
      (_) {},
    );
  }

  int idFor(String method) =>
      (calls.lastWhere((c) => c.method == method).arguments as Map)['adId'] as int;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    calls = [];
    consentAllowed = true;
    firstConsentGate = null;
    sdkGate = null;
    consentRequests = 0;
    cache = Cache();
    when(() => cache.write(any(), any(), ttl: any(named: 'ttl'))).thenAnswer((_) async {});
    messenger.setMockMethodCallHandler(ump, (call) async {
      if (call.method == 'ConsentInformation#requestConsentInfoUpdate' && ++consentRequests == 1) {
        await firstConsentGate?.future;
      }
      if (call.method == 'ConsentInformation#canRequestAds') return consentAllowed;
      if (call.method == 'ConsentInformation#getPrivacyOptionsRequirementStatus') return 1;
      return null;
    });
    messenger.setMockMethodCallHandler(instanceManager.channel, (call) async {
      calls.add(call);
      if (call.method == 'MobileAds#initialize') {
        await sdkGate?.future;
        return InitializationStatus({});
      }
      if (call.method.contains('AdaptiveBannerAdSize')) return 50;
      return null;
    });
    ads = AdService(cache);
    ads.sessionActive = true;
  });
  tearDown(() async {
    ads.dispose();
    await Future<void>.delayed(Duration.zero);
    messenger.setMockMethodCallHandler(ump, null);
    messenger.setMockMethodCallHandler(instanceManager.channel, null);
    debugDefaultTargetPlatformOverride = null;
  });
  test('initialization is single-flight and consent gates all requests', () async {
    await Future.wait([ads.initialize(), ads.initialize()]);
    expect(ads.ready, true);
    expect(ads.privacyRequired, true);
    expect(calls.where((c) => c.method == 'MobileAds#initialize').length, 1);
    expect(calls.where((c) => c.method == 'loadRewardedAd').length, 1);
  });
  test('no SDK or ad requests when consent does not permit them', () async {
    consentAllowed = false;
    await ads.initialize();
    expect(ads.ready, false);
    expect(calls, isEmpty);
  });
  test('an old consent callback cannot initialize or load for a new session', () async {
    firstConsentGate = Completer<void>();
    final old = ads.initialize();
    await Future<void>.delayed(Duration.zero);
    ads.endUserSession();
    ads.sessionActive = true;
    await ads.initialize();
    firstConsentGate!.complete();
    await old;
    expect(calls.where((c) => c.method == 'MobileAds#initialize').length, 1);
    expect(calls.where((c) => c.method == 'loadRewardedAd').length, 1);
  });
  test('SDK initialization remains single-flight across a session change', () async {
    sdkGate = Completer<void>();
    final old = ads.initialize();
    for (var i = 0; i < 10 && !calls.any((c) => c.method == 'MobileAds#initialize'); i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(calls.any((c) => c.method == 'MobileAds#initialize'), true);
    ads.endUserSession();
    ads.sessionActive = true;
    final current = ads.initialize();
    await Future<void>.delayed(Duration.zero);
    sdkGate!.complete();
    await Future.wait([old, current]);
    expect(calls.where((c) => c.method == 'MobileAds#initialize').length, 1);
    expect(calls.where((c) => c.method == 'loadRewardedAd').length, 1);
  });
  test('third navigation counts once per route, same giveaway reopened counts again', () async {
    await ads.initialize();
    await event(idFor('loadInterstitialAd'), 'onAdLoaded');
    final observer = AdNavigationObserver(ads);
    MaterialPageRoute<void> route() => MaterialPageRoute(
      settings: const RouteSettings(name: '/giveaway/same'),
      builder: (_) => const SizedBox(),
    );
    final first = route();
    observer.didPush(first, null);
    observer.didPush(first, null);
    observer.didPop(first, null);
    final second = route();
    observer.didPush(second, null);
    observer.didPop(second, null);
    final third = route();
    observer.didPush(third, null);
    await Future<void>.delayed(Duration.zero);
    expect(ads.frequency.entries, 3);
    expect(calls.where((c) => c.method == 'showAdWithoutView').length, 1);
    await event(idFor('loadInterstitialAd'), 'onAdDismissedFullScreenContent');
    expect(ads.frequency.fullscreenShowing, false);
  });
  test('participation interstitial is disabled even when an ad is ready', () async {
    await ads.initialize();
    final id = idFor('loadInterstitialAd');
    await event(id, 'onAdLoaded');
    ads.frequency.criticalFlows++;
    expect(await ads.showParticipationInterstitial(), false);
    expect(calls.where((c) => c.method == 'showAdWithoutView'), isEmpty);
    expect(ads.frequency.fullscreenShowing, false);
    ads.frequency.criticalFlows--;
  });
  test('reward callback alone never creates participation; result waits for dismissal', () async {
    await ads.initialize();
    final id = idFor('loadRewardedAd');
    await event(id, 'onAdLoaded');
    var complete = false;
    final result = ads.showRewarded().then((v) {
      complete = true;
      return v;
    });
    await Future<void>.delayed(Duration.zero);
    expect(complete, false);
    await event(id, 'onRewardedAdUserEarnedReward', {'rewardItem': RewardItem(1, 'optional')});
    await event(id, 'onRewardedAdUserEarnedReward', {'rewardItem': RewardItem(1, 'optional')});
    expect(complete, false);
    await event(id, 'onAdDismissedFullScreenContent');
    expect(await result, true);
  });
  test('closing rewarded without reward is safe and releases the fullscreen lock', () async {
    await ads.initialize();
    final id = idFor('loadRewardedAd');
    await event(id, 'onAdLoaded');
    final result = ads.showRewarded();
    await Future<void>.delayed(Duration.zero);
    await event(id, 'onAdDismissedFullScreenContent');
    expect(await result, false);
    expect(ads.frequency.fullscreenShowing, false);
  });
  test('unavailable rewarded returns immediately', () async {
    expect(await ads.showRewarded(), false);
  });
  test('banner is reused for the same width and disposed on session end', () async {
    await ads.initialize();
    await ads.ensureBanner(360);
    await ads.ensureBanner(360);
    expect(calls.where((c) => c.method == 'loadBannerAd').length, 1);
    final id = idFor('loadBannerAd');
    await event(id, 'onAdLoaded');
    expect(ads.bannerLoaded, true);
    ads.endUserSession();
    expect(ads.bannerLoaded, false);
    expect(ads.banner, null);
  });
  test('background/resume does not increment details entries', () async {
    ads.didChangeAppLifecycleState(AppLifecycleState.paused);
    ads.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(ads.frequency.entries, 0);
  });
  test('App Open requires Home, suppresses overlap, and reloads after dismissal', () async {
    TestWidgetsFlutterBinding.ensureInitialized().handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await ads.initialize();
    final id = idFor('loadAppOpenAd');
    await event(id, 'onAdLoaded');
    final home = MaterialPageRoute<void>(builder: (_) => const SizedBox());
    ads.homeRoute = home;
    ads.showAppOpen();
    expect(calls.where((c) => c.method == 'showAdWithoutView'), isEmpty);
    ads.topRoute = home;
    ads.showAppOpen();
    expect(ads.frequency.fullscreenShowing, true);
    expect(calls.where((c) => c.method == 'showAdWithoutView').length, 1);
    expect(await ads.showRewarded(), false);
    await event(id, 'onAdDismissedFullScreenContent');
    expect(ads.frequency.fullscreenShowing, false);
    expect(calls.where((c) => c.method == 'loadAppOpenAd').length, 2);
    await event(idFor('loadAppOpenAd'), 'onAdLoaded');
    ads.showAppOpen();
    expect(calls.where((c) => c.method == 'showAdWithoutView').length, 1);
  });
  test('rewarded show failure releases lock and returns no reward', () async {
    await ads.initialize();
    final id = idFor('loadRewardedAd');
    await event(id, 'onAdLoaded');
    final result = ads.showRewarded();
    await Future<void>.delayed(Duration.zero);
    await event(id, 'onFailedToShowFullScreenContent', {
      'error': AdError(0, 'mock', 'show failed'),
    });
    expect(await result, false);
    expect(ads.frequency.fullscreenShowing, false);
  });
  test('banner failure collapses placement; retries are cancelled on exit', () async {
    await ads.initialize();
    await ads.ensureBanner(320);
    await event(idFor('loadBannerAd'), 'onAdFailedToLoad', {
      'loadAdError': LoadAdError(0, 'mock', 'no fill', null),
    });
    expect(ads.banner, null);
    expect(ads.bannerLoaded, false);
    ads.endUserSession();
  });
  test('stale load callbacks after session exit cannot retain ads', () async {
    await ads.initialize();
    final id = idFor('loadRewardedAd');
    ads.endUserSession();
    await event(id, 'onAdLoaded');
    expect(ads.rewardedAvailable, false);
    expect(calls.where((c) => c.method == 'showAdWithoutView'), isEmpty);
  });
  test('replaced routes and non-detail pushes never add an entry', () async {
    final observer = AdNavigationObserver(ads);
    final details = MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/giveaway/same'),
      builder: (_) => const SizedBox(),
    );
    final other = MaterialPageRoute<void>(builder: (_) => const SizedBox());
    observer.didReplace(newRoute: details, oldRoute: other);
    observer.didPush(other, details);
    observer.didPop(other, details);
    expect(ads.frequency.entries, 0);
  });
}
