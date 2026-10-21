// QA-only entrypoint. Never used by lib/main.dart or the production AAB.
// Exercises native Google demo ads without participant data or Supabase access.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:rewardsapp/services/ads/ad_constants.dart';

Future<void> main() async {
  if (kReleaseMode || !AdConstants.testAds) throw StateError('Debug demo ads only');
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const MaterialApp(home: NativeAdSmoke()));
}

class NativeAdSmoke extends StatefulWidget {
  const NativeAdSmoke({super.key});
  @override
  State<NativeAdSmoke> createState() => _NativeAdSmokeState();
}

class _NativeAdSmokeState extends State<NativeAdSmoke> {
  BannerAd? _banner;
  AppOpenAd? _open;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _bannerLoaded = false;
  bool _showing = false;
  bool _loadingBanner = false;
  final _events = <String>[];
  void _record(String value) {
    debugPrint('REWARDS_QA: $value');
    if (mounted) setState(() => _events.add(value));
  }

  @override
  void initState() {
    super.initState();
    AppOpenAd.load(
      adUnitId: AdConstants.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _open = ad;
          _record('App Open loaded');
        },
        onAdFailedToLoad: (error) => _record('App Open load failed: ${error.code}'),
      ),
    );
    InterstitialAd.load(
      adUnitId: AdConstants.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _record('Interstitial loaded');
        },
        onAdFailedToLoad: (error) => _record('Interstitial load failed: ${error.code}'),
      ),
    );
    RewardedAd.load(
      adUnitId: AdConstants.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _record('Rewarded loaded');
        },
        onAdFailedToLoad: (error) => _record('Rewarded load failed: ${error.code}'),
      ),
    );
  }

  Future<void> _loadBanner(int width) async {
    if (_banner != null || _loadingBanner) return;
    _loadingBanner = true;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;
    _banner = BannerAd(
      adUnitId: AdConstants.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _bannerLoaded = true;
          _record('Banner loaded ${size.width}x${size.height}');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _record('Banner load failed: ${error.code}');
        },
      ),
    );
    await _banner!.load();
  }

  void _show(String format) {
    if (_showing) return;
    final AdWithoutView? ad = switch (format) {
      'App Open' => _open,
      'Interstitial' => _interstitial,
      _ => _rewarded,
    };
    if (ad == null) return;
    _showing = true;
    void finished(String result) {
      _showing = false;
      ad.dispose();
      _record('$format $result');
    }

    FullScreenContentCallback<T> callback<T extends Ad>() => FullScreenContentCallback<T>(
      onAdShowedFullScreenContent: (_) => _record('$format shown'),
      onAdDismissedFullScreenContent: (_) => finished('dismissed'),
      onAdFailedToShowFullScreenContent: (_, error) => finished('show failed: ${error.code}'),
    );
    if (ad is AppOpenAd) {
      _open = null;
      ad.fullScreenContentCallback = callback<AppOpenAd>();
      ad.show();
    } else if (ad is InterstitialAd) {
      _interstitial = null;
      ad.fullScreenContentCallback = callback<InterstitialAd>();
      ad.show();
    } else if (ad is RewardedAd) {
      _rewarded = null;
      ad.fullScreenContentCallback = callback<RewardedAd>();
      ad.show(onUserEarnedReward: (_, _) => _record('Reward callback received; no entry created'));
    }
  }

  @override
  void dispose() {
    _banner?.dispose();
    _open?.dispose();
    _interstitial?.dispose();
    _rewarded?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('QA: Google demo ads only')),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _loadBanner(constraints.maxWidth.floor()),
          );
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Test harness; consent is mocked. No Supabase or participation data. Production consent is never bypassed.',
                ),
              ),
              for (final label in ['App Open', 'Interstitial', 'Rewarded'])
                ElevatedButton(onPressed: () => _show(label), child: Text('Show $label test ad')),
              Expanded(
                child: ListView(children: _events.map((e) => ListTile(title: Text(e))).toList()),
              ),
              if (_bannerLoaded && _banner != null)
                SizedBox(
                  width: _banner!.size.width.toDouble(),
                  height: _banner!.size.height.toDouble(),
                  child: AdWidget(ad: _banner!),
                ),
            ],
          );
        },
      ),
    ),
  );
}
