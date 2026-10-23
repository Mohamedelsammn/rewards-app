/// One fullscreen ad at a time, app-wide (App Open, Interstitial and
/// Rewarded), plus the time since the last one ended for frequency caps.
class FullscreenAdGate {
  FullscreenAdGate({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  bool _showing = false;
  DateTime? _lastEnded;

  /// A fullscreen ad is on screen (or the user left the app from it).
  bool get showing => _showing;

  DateTime get now => _clock();

  /// Whether an automatic (not user-requested) ad may start now: nothing on
  /// screen and at least [gap] since the last fullscreen ad ended.
  bool allows(Duration gap) {
    if (_showing) return false;
    final last = _lastEnded;
    return last == null || _clock().difference(last) >= gap;
  }

  /// Time since the last fullscreen ad ended, or `null` if none yet.
  Duration? get sinceLast {
    final last = _lastEnded;
    return last == null ? null : _clock().difference(last);
  }

  /// Runs [show] as the only fullscreen ad; returns `null` without running
  /// it when another one is showing.
  Future<T?> run<T>(Future<T> Function() show) async {
    if (_showing) return null;
    _showing = true;
    try {
      return await show();
    } finally {
      _showing = false;
      _lastEnded = _clock();
    }
  }
}
