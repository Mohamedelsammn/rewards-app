import '../ad_diagnostics.dart';
import 'fullscreen_ad.dart';
import 'fullscreen_ad_gate.dart';

/// Counts user-initiated Giveaway Details openings: every [every]th one
/// shows the preloaded interstitial before navigating, if it is ready and
/// no fullscreen ad ended within [minGap]. Otherwise navigation is
/// immediate. The ad only ever plays at the transition, never on the
/// details screen itself.
class GiveawayInterstitialPacer {
  GiveawayInterstitialPacer({
    required this.slot,
    required this.gate,
    this.every = 3,
    this.minGap = const Duration(minutes: 2),
  });

  final PreloadedAdSlot slot;
  final FullscreenAdGate gate;
  final int every;
  final Duration minGap;

  int _openings = 0;
  bool _busy = false;

  int get openings => _openings;

  /// Warms the slot (the first ad can play on the [every]th opening).
  void preload() => slot.preload();

  void dispose() => slot.dispose();

  /// Call once per user tap, before pushing the details route; returns
  /// `false` while a previous opening is still in progress (double tap),
  /// in which case the caller must not navigate again.
  Future<bool> beforeOpening() async {
    if (_busy) return false;
    _busy = true;
    try {
      _openings++;
      if (_openings % every != 0) {
        if (_openings % every == every - 1) slot.preload();
        return true;
      }
      if (!slot.isReady || !gate.allows(minGap)) {
        adLog('interstitial skipped on opening $_openings (ready=${slot.isReady})');
        slot.preload();
        return true;
      }
      final ad = slot.take();
      if (ad != null) {
        final shown = await showGated(gate, ad) ?? false;
        adLog('interstitial on opening $_openings shown=$shown');
      }
      slot.preload();
      return true;
    } finally {
      _busy = false;
    }
  }
}
