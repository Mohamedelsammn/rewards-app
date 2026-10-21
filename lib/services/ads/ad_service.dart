import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../cache/cache_service.dart';
import 'ad_constants.dart';
import 'ad_frequency_controller.dart';

/// One application-owned SDK/consent/lifecycle boundary. No number allocation here.
class AdService extends ChangeNotifier with WidgetsBindingObserver {
  AdService(this._cache) {
    frequency = AdFrequencyController(
      entries: _cache.read<int>('ads.details.entries', (v) => v as int) ?? 0,
    );
    WidgetsBinding.instance.addObserver(this);
  }
  final CacheService _cache;
  late final AdFrequencyController frequency;
  Future<void>? _initializing;
  Future<void>? _sdkInitializing;
  bool _sdkInitialized = false;
  bool ready = false;
  bool privacyRequired = false;
  bool sessionActive = false;
  bool _disposed = false;
  int _epoch = 0;
  Route<dynamic>? homeRoute;
  Route<dynamic>? topRoute;
  DateTime? _backgrounded;
  DateTime? _coldUntil;
  AppOpenAd? _open;
  DateTime? _openLoaded;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  BannerAd? banner;
  AdSize? bannerSize;
  bool bannerLoaded = false;
  int _bannerWidth = 0;
  final Set<String> _loading = {};
  final Map<String, int> _attempts = {};
  final Map<String, Timer> _retries = {};
  static const request = AdRequest(nonPersonalizedAds: true);
  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get canLoad => supported && ready && sessionActive && !_disposed;
  bool get rewardedAvailable => canLoad && _rewarded != null;
  bool get homeVisible => homeRoute != null && identical(homeRoute, topRoute);

  Future<void> startUserSession(Route<dynamic>? route) async {
    sessionActive = true;
    homeRoute = route;
    // Consent never overlays the preserved splash. First session is ad-open onboarding-free.
    final launches = _cache.read<int>('ads.launches', (v) => v as int) ?? 0;
    await _cache.write('ads.launches', launches + 1, ttl: const Duration(days: 3650));
    if (!sessionActive || _disposed) return;
    if (launches >= 2) _coldUntil = DateTime.now().add(const Duration(seconds: 2));
    await initialize();
  }

  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    if (!supported || _disposed) return;
    final epoch = _epoch;
    try {
      final consent = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          ConsentForm.loadAndShowConsentFormIfRequired((_) {
            if (!consent.isCompleted) consent.complete();
          });
        },
        (_) {
          if (!consent.isCompleted) consent.complete();
        },
      );
      await consent.future;
      if (_disposed || !sessionActive || epoch != _epoch) return;
      privacyRequired =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
      // Fail closed; UMP may permit an existing valid choice after update failure.
      final canRequest = await ConsentInformation.instance.canRequestAds();
      if (_disposed || !sessionActive || epoch != _epoch) return;
      if (!canRequest) {
        notifyListeners();
        return;
      }
      if (!_sdkInitialized) {
        await (_sdkInitializing ??= _initializeSdk());
      }
      if (_disposed || !sessionActive || epoch != _epoch) return;
      ready = true;
      notifyListeners();
      _loadOpen();
      _loadInterstitial();
      _loadRewarded();
      if (_bannerWidth > 0) unawaited(ensureBanner(_bannerWidth));
    } catch (_) {
      if (epoch == _epoch && !_disposed) ready = false;
    }
  }

  Future<void> _initializeSdk() async {
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.pg),
      );
      await MobileAds.instance.initialize();
      _sdkInitialized = true;
    } catch (_) {
      _sdkInitializing = null;
      rethrow;
    }
  }

  void _retry(String format, void Function() load) {
    _loading.remove(format);
    if (!canLoad || _retries.containsKey(format)) return;
    final attempt = (_attempts[format] ?? 0) + 1;
    _attempts[format] = attempt;
    _retries[format] = Timer(Duration(seconds: math.min(300, 5 * (1 << math.min(attempt, 6)))), () {
      _retries.remove(format);
      if (canLoad) load();
    });
  }

  bool _begin(String format) => canLoad && !_retries.containsKey(format) && _loading.add(format);
  void _loadFailed(String format, int epoch, void Function() load) {
    if (epoch == _epoch && !_disposed) _retry(format, load);
  }

  bool _accept(String format, int epoch, Ad ad) {
    if (!canLoad || epoch != _epoch) {
      ad.dispose();
      return false;
    }
    _loading.remove(format);
    _attempts.remove(format);
    return true;
  }

  void _loadInterstitial() {
    if (_interstitial != null || !_begin('interstitial')) return;
    final epoch = _epoch;
    InterstitialAd.load(
      adUnitId: AdConstants.interstitial,
      request: request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (_accept('interstitial', epoch, ad)) _interstitial = ad;
        },
        onAdFailedToLoad: (_) => _loadFailed('interstitial', epoch, _loadInterstitial),
      ),
    ).catchError((Object _) => _loadFailed('interstitial', epoch, _loadInterstitial));
  }

  void _loadRewarded() {
    if (_rewarded != null || !_begin('rewarded')) return;
    final epoch = _epoch;
    RewardedAd.load(
      adUnitId: AdConstants.rewarded,
      request: request,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (_accept('rewarded', epoch, ad)) {
            _rewarded = ad;
            notifyListeners();
          }
        },
        onAdFailedToLoad: (_) => _loadFailed('rewarded', epoch, _loadRewarded),
      ),
    ).catchError((Object _) => _loadFailed('rewarded', epoch, _loadRewarded));
  }

  void _loadOpen() {
    if (_open != null || !_begin('open')) return;
    final epoch = _epoch;
    AppOpenAd.load(
      adUnitId: AdConstants.appOpen,
      request: request,
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          if (_accept('open', epoch, ad)) {
            _open = ad;
            _openLoaded = DateTime.now();
            if (_coldUntil != null && DateTime.now().isBefore(_coldUntil!)) showAppOpen();
          }
        },
        onAdFailedToLoad: (_) => _loadFailed('open', epoch, _loadOpen),
      ),
    ).catchError((Object _) => _loadFailed('open', epoch, _loadOpen));
  }

  Future<void> detailsEntry() async {
    final opportunity = frequency.recordDetailsEntry();
    unawaited(
      _cache.write('ads.details.entries', frequency.entries, ttl: const Duration(days: 3650)),
    );
    if (!opportunity) return;
    await _showInterstitial();
  }

  /// Participation must never trigger an interstitial. Entry is completed
  /// through the free path, with an optional rewarded-ad choice handled
  /// separately by the participation flow.
  Future<bool> showParticipationInterstitial() async => false;

  Future<bool> _showInterstitial({bool completedCriticalFlow = false}) async {
    final ad = _interstitial;
    if (!canLoad ||
        ad == null ||
        !frequency.tryAcquire(interstitial: true, completedCriticalFlow: completedCriticalFlow)) {
      return false;
    }
    _interstitial = null;
    final completed = Completer<bool>();
    var didFinish = false;
    var wasShown = false;
    void finish(bool shown) {
      if (didFinish) return;
      didFinish = true;
      ad.dispose();
      frequency.release();
      _loadInterstitial();
      if (!completed.isCompleted) completed.complete(shown);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => wasShown = true,
      onAdDismissedFullScreenContent: (_) => finish(wasShown),
      onAdFailedToShowFullScreenContent: (_, _) => finish(false),
    );
    try {
      await ad.show();
    } catch (_) {
      finish(false);
    }
    return completed.future;
  }

  void showAppOpen() {
    _coldUntil = null;
    if (!canLoad ||
        !homeVisible ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    if (_openLoaded == null ||
        DateTime.now().difference(_openLoaded!) >= const Duration(hours: 4)) {
      _open?.dispose();
      _open = null;
      _loadOpen();
      return;
    }
    final ad = _open;
    if (ad == null || !frequency.tryAcquire(appOpen: true)) return;
    _open = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) {
        ad.dispose();
        frequency.release();
        _loadOpen();
      },
      onAdFailedToShowFullScreenContent: (_, _) {
        ad.dispose();
        frequency.release();
        _loadOpen();
      },
    );
    ad.show().catchError((Object _) {
      ad.dispose();
      frequency.release();
      _loadOpen();
    });
  }

  /// Completes on dismissal. A Google reward callback is recorded separately;
  /// closing without it grants no ad reward and still allows the normal free entry.
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (!canLoad || ad == null || !frequency.tryAcquire(rewarded: true)) return false;
    _rewarded = null;
    var earned = false;
    final done = Completer<bool>();
    void finish() {
      if (done.isCompleted) return;
      ad.dispose();
      frequency.release();
      _loadRewarded();
      done.complete(earned);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, _) => finish(),
    );
    try {
      await ad.show(
        onUserEarnedReward: (_, _) {
          earned = true;
        },
      );
    } catch (_) {
      finish();
    }
    return done.future;
  }

  Future<void> ensureBanner(int width) async {
    if (_bannerWidth != width) {
      banner?.dispose();
      banner = null;
      bannerSize = null;
      bannerLoaded = false;
      _bannerWidth = width;
      notifyListeners();
    }
    if (width <= 0 || banner != null || !_begin('banner')) return;
    final epoch = _epoch;
    try {
      final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (_disposed || epoch != _epoch) return;
      if (size == null || !canLoad || epoch != _epoch || width != _bannerWidth) {
        _loading.remove('banner');
        if (canLoad && epoch == _epoch && width != _bannerWidth) {
          unawaited(ensureBanner(_bannerWidth));
        }
        return;
      }
      final ad = BannerAd(
        adUnitId: AdConstants.banner,
        size: size,
        request: request,
        listener: BannerAdListener(
          onAdLoaded: (ad) async {
            if (!_accept('banner', epoch, ad)) return;
            if (!identical(banner, ad)) {
              ad.dispose();
              unawaited(ensureBanner(_bannerWidth));
              return;
            }
            // Adaptive requests may resolve to a smaller native creative. Size
            // the platform view using the SDK's actual dimensions, not a guess.
            AdSize? resolved;
            try {
              resolved = await (ad as BannerAd).getPlatformAdSize();
            } catch (_) {
              // Older/failed platform responses can use the requested size.
            }
            if (!canLoad || epoch != _epoch || !identical(banner, ad)) return;
            bannerSize = resolved != null && resolved.width > 0 && resolved.height > 0
                ? resolved
                : (ad as BannerAd).size;
            bannerLoaded = true;
            notifyListeners();
          },
          onAdFailedToLoad: (ad, _) {
            ad.dispose();
            if (_disposed || epoch != _epoch) return;
            if (identical(banner, ad)) {
              banner = null;
              bannerSize = null;
              bannerLoaded = false;
              notifyListeners();
            }
            _retry('banner', () => unawaited(ensureBanner(_bannerWidth)));
          },
        ),
      );
      banner = ad;
      await ad.load();
    } catch (_) {
      if (_disposed || epoch != _epoch) return;
      banner?.dispose();
      banner = null;
      _retry('banner', () => unawaited(ensureBanner(_bannerWidth)));
    }
  }

  Future<void> privacyOptions() async {
    if (!supported || frequency.fullscreenShowing) return;
    frequency.criticalFlows++;
    _clearAds();
    ready = false;
    notifyListeners();
    final done = Completer<void>();
    try {
      ConsentForm.showPrivacyOptionsForm((_) {
        if (!done.isCompleted) done.complete();
      });
      await done.future;
      _initializing = null;
      await initialize();
    } finally {
      frequency.criticalFlows--;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused &&
        !frequency.fullscreenShowing &&
        frequency.criticalFlows == 0) {
      _backgrounded = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      final since = _backgrounded;
      _backgrounded = null;
      if (since != null && DateTime.now().difference(since) >= const Duration(seconds: 30)) {
        showAppOpen();
      }
    }
  }

  void _clearAds() {
    _epoch++;
    for (final timer in _retries.values) {
      timer.cancel();
    }
    _retries.clear();
    _loading.clear();
    _open?.dispose();
    _interstitial?.dispose();
    _rewarded?.dispose();
    banner?.dispose();
    _open = null;
    _interstitial = null;
    _rewarded = null;
    banner = null;
    bannerSize = null;
    bannerLoaded = false;
  }

  void endUserSession() {
    sessionActive = false;
    homeRoute = null;
    _coldUntil = null;
    _clearAds();
    _initializing = null;
    ready = false;
  }

  @override
  void dispose() {
    _disposed = true;
    _clearAds();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class AdNavigationObserver extends NavigatorObserver {
  AdNavigationObserver(this.ads);
  final AdService ads;
  final Set<Route<dynamic>> _seen = {};
  void _top(Route<dynamic>? route) {
    ads.topRoute = route;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _top(route);
    if (route.settings.name?.startsWith('/giveaway/') == true && _seen.add(route)) {
      unawaited(ads.detailsEntry());
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _seen.remove(route);
    _top(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _seen.remove(route);
    if (identical(ads.topRoute, route)) _top(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _seen.remove(oldRoute);
    _top(newRoute);
  }
}
