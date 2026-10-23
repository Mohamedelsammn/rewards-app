import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ad_diagnostics.dart';
import 'fullscreen_ad_gate.dart';

/// Automatic fullscreen formats (App Open and Interstitial).
enum FullscreenAdFormat { appOpen, interstitial }

/// A loaded fullscreen ad. [show] completes when the ad is dismissed or
/// fails to show, with `true` only when it was actually displayed.
abstract interface class FullscreenAd {
  Future<bool> show();
  void dispose();
}

/// Shows [ad] as the gate's only fullscreen ad, bounded by [timeout] in
/// case its dismissal callback never arrives (the gate is then released and
/// the ad disposed). `null` when another fullscreen ad is up.
Future<bool?> showGated(
  FullscreenAdGate gate,
  FullscreenAd ad, {
  Duration timeout = const Duration(minutes: 5),
}) async {
  final shown = await gate.run(
    () => ad.show().timeout(
      timeout,
      onTimeout: () {
        adLog('fullscreen dismissal timed out');
        ad.dispose();
        return true;
      },
    ),
  );
  if (shown == null) ad.dispose();
  return shown;
}

/// Loads fullscreen ads; the SDK in the app, fakes in tests.
abstract interface class FullscreenAdLoader {
  /// The loaded ad, or `null` when none is available (no fill, error,
  /// consent does not allow requests).
  Future<FullscreenAd?> load(FullscreenAdFormat format, String adUnitId);
}

/// One preloaded ad of a format: loads in the background, retries failures
/// with a capped backoff, and drops ads older than [maxAge] (AdMob: App Open
/// ads expire after 4 h, interstitials after 1 h).
class PreloadedAdSlot {
  PreloadedAdSlot({
    required this.format,
    required this.adUnitId,
    required this._loader,
    required this.maxAge,
    DateTime Function()? clock,
    this.retryDelays = const [Duration(seconds: 10), Duration(seconds: 30), Duration(minutes: 2)],
    this.loadTimeout = const Duration(seconds: 30),
  }) : _clock = clock ?? DateTime.now;

  final FullscreenAdFormat format;
  final String adUnitId;
  final FullscreenAdLoader _loader;
  final Duration maxAge;
  final DateTime Function() _clock;
  final List<Duration> retryDelays;

  /// A load whose callback never arrives counts as a failure (and retries).
  final Duration loadTimeout;

  FullscreenAd? _ad;
  DateTime? _loadedAt;
  Future<void>? _loading;
  Timer? _retry;
  int _failures = 0;
  bool _disposed = false;

  bool get enabled => adUnitId.isNotEmpty;

  /// A fresh ad is ready to show.
  bool get isReady {
    final at = _loadedAt;
    if (_ad == null || at == null) return false;
    if (_clock().difference(at) < maxAge) return true;
    _drop();
    return false;
  }

  /// Starts loading unless an ad is ready or a load is running.
  Future<void> preload() {
    if (!enabled || _disposed || isReady) return Future.value();
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    _retry?.cancel();
    final started = _clock();
    FullscreenAd? ad;
    try {
      final pending = _loader.load(format, adUnitId);
      ad = await pending.timeout(
        loadTimeout,
        onTimeout: () {
          // Released if it arrives after all.
          pending.then((late) => late?.dispose()).ignore();
          return null;
        },
      );
    } catch (error) {
      adLog('${format.name} load threw ${error.runtimeType}');
      ad = null;
    }
    if (_disposed) {
      ad?.dispose();
      return;
    }
    if (ad == null) {
      final delay = retryDelays[_failures.clamp(0, retryDelays.length - 1)];
      _failures++;
      adLog('${format.name} unavailable; retry in ${delay.inSeconds} s');
      _retry = Timer(delay, () => preload());
      return;
    }
    _failures = 0;
    _ad = ad;
    _loadedAt = _clock();
    adLog('${format.name} loaded in ${_clock().difference(started).inMilliseconds} ms');
  }

  /// Waits up to [timeout] for a load in progress (startup only).
  Future<bool> readyWithin(Duration timeout) async {
    if (isReady) return true;
    final loading = preload();
    try {
      await loading.timeout(timeout);
    } on TimeoutException {
      return false;
    }
    return isReady;
  }

  /// Hands over the ready ad (the slot then loads the next one after it is
  /// shown, see [preload]).
  FullscreenAd? take() {
    if (!isReady) return null;
    final ad = _ad;
    _ad = null;
    _loadedAt = null;
    return ad;
  }

  void _drop() {
    _ad?.dispose();
    _ad = null;
    _loadedAt = null;
  }

  void dispose() {
    _disposed = true;
    _retry?.cancel();
    _drop();
  }
}

/// Google Mobile Ads implementation of [FullscreenAdLoader].
class GoogleFullscreenAdLoader implements FullscreenAdLoader {
  const GoogleFullscreenAdLoader({required this.ready});

  /// SDK initialized and consent allows ad requests.
  final Future<bool> Function() ready;

  @override
  Future<FullscreenAd?> load(FullscreenAdFormat format, String adUnitId) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android || !await ready()) return null;
    final loaded = Completer<FullscreenAd?>();
    void failed(LoadAdError error) {
      adWarn(
        '${format.name} load failed code=${error.code} domain=${error.domain} '
        'message=${error.message}',
      );
      if (!loaded.isCompleted) loaded.complete(null);
    }

    const request = AdRequest(nonPersonalizedAds: true);
    switch (format) {
      case FullscreenAdFormat.appOpen:
        await AppOpenAd.load(
          adUnitId: adUnitId,
          request: request,
          adLoadCallback: AppOpenAdLoadCallback(
            onAdLoaded: (ad) => loaded.complete(_GoogleAd(ad)),
            onAdFailedToLoad: failed,
          ),
        );
      case FullscreenAdFormat.interstitial:
        await InterstitialAd.load(
          adUnitId: adUnitId,
          request: request,
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (ad) => loaded.complete(_GoogleAd(ad)),
            onAdFailedToLoad: failed,
          ),
        );
    }
    return loaded.future;
  }
}

class _GoogleAd implements FullscreenAd {
  _GoogleAd(this._ad);

  final AdWithoutView _ad;

  @override
  Future<bool> show() {
    final done = Completer<bool>();
    switch (_ad) {
      case final AppOpenAd ad:
        ad
          ..fullScreenContentCallback = _callback<AppOpenAd>(done)
          ..show();
      case final InterstitialAd ad:
        ad
          ..fullScreenContentCallback = _callback<InterstitialAd>(done)
          ..show();
      default:
        done.complete(false);
    }
    return done.future;
  }

  static FullScreenContentCallback<T> _callback<T extends Ad>(Completer<bool> done) {
    var shown = false;
    return FullScreenContentCallback<T>(
      onAdShowedFullScreenContent: (_) => shown = true,
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!done.isCompleted) done.complete(shown);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        adWarn('fullscreen show failed code=${error.code} message=${error.message}');
        ad.dispose();
        if (!done.isCompleted) done.complete(false);
      },
    );
  }

  @override
  void dispose() => _ad.dispose();
}
