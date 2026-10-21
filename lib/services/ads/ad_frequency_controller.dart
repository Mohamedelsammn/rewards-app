class AdFrequencyController {
  AdFrequencyController({this.entries = 0, DateTime Function()? now}) : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  int entries;
  bool fullscreenShowing = false;
  int criticalFlows = 0;
  DateTime? _lastFullscreen;
  DateTime? _lastAppOpen;
  DateTime? _lastInterstitial;
  static const interstitialCooldown = Duration(seconds: 90);
  bool recordDetailsEntry() => ++entries % 3 == 0;
  bool tryAcquire({
    bool rewarded = false,
    bool appOpen = false,
    bool interstitial = false,
    bool completedCriticalFlow = false,
  }) {
    final now = _now();
    if (fullscreenShowing) return false;
    if (completedCriticalFlow && criticalFlows != 1) return false;
    if (!rewarded && criticalFlows > 0 && !completedCriticalFlow) return false;
    if (interstitial &&
        _lastInterstitial != null &&
        now.difference(_lastInterstitial!) < interstitialCooldown) {
      return false;
    }
    if (!rewarded &&
        !interstitial &&
        _lastFullscreen != null &&
        now.difference(_lastFullscreen!) < const Duration(seconds: 90)) {
      return false;
    }
    if (appOpen &&
        _lastAppOpen != null &&
        now.difference(_lastAppOpen!) < const Duration(minutes: 10)) {
      return false;
    }
    fullscreenShowing = true;
    if (interstitial) _lastInterstitial = now;
    if (appOpen) _lastAppOpen = now;
    return true;
  }

  void release() {
    fullscreenShowing = false;
    _lastFullscreen = _now();
  }
}
