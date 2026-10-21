import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/services/ads/ad_frequency_controller.dart';
import 'package:rewardsapp/services/ads/ad_constants.dart';

void main() {
  test('every third genuine entry, including reopening the same ID', () {
    final controller = AdFrequencyController();
    expect(List.generate(9, (_) => controller.recordDetailsEntry()), [
      false,
      false,
      true,
      false,
      false,
      true,
      false,
      false,
      true,
    ]);
    expect(AdFrequencyController(entries: controller.entries).recordDetailsEntry(), false);
  });
  test('fullscreen formats cannot overlap; critical participation blocks automatic formats', () {
    var now = DateTime(2026);
    final controller = AdFrequencyController(now: () => now);
    controller.criticalFlows++;
    expect(controller.tryAcquire(), false);
    expect(controller.tryAcquire(appOpen: true), false);
    expect(controller.tryAcquire(rewarded: true), true);
    expect(controller.tryAcquire(rewarded: true), false);
    controller.release();
    controller.criticalFlows--;
    expect(controller.tryAcquire(), false);
    now = now.add(const Duration(seconds: 91));
    expect(controller.tryAcquire(), true);
  });
  test('App Open has a ten minute cap in addition to the global cap', () {
    var now = DateTime(2026);
    final controller = AdFrequencyController(now: () => now);
    expect(controller.tryAcquire(appOpen: true), true);
    controller.release();
    now = now.add(const Duration(minutes: 2));
    expect(controller.tryAcquire(appOpen: true), false);
    now = now.add(const Duration(minutes: 9));
    expect(controller.tryAcquire(appOpen: true), true);
  });
  test('a third-entry interstitial opportunity is not suppressed by app-open cooldown', () {
    var now = DateTime(2026);
    final controller = AdFrequencyController(now: () => now);
    expect(controller.tryAcquire(appOpen: true), true);
    controller.release();
    expect(controller.tryAcquire(interstitial: true), true);
    controller.release();
    expect(controller.tryAcquire(interstitial: true), false);
    now = now.add(AdFrequencyController.interstitialCooldown);
    expect(controller.tryAcquire(interstitial: true), true);
  });
  test('participation completion can use its own critical-flow slot, but not overlap', () {
    final controller = AdFrequencyController();
    controller.criticalFlows++;
    expect(controller.tryAcquire(interstitial: true), false);
    expect(controller.tryAcquire(interstitial: true, completedCriticalFlow: true), true);
    expect(controller.tryAcquire(interstitial: true, completedCriticalFlow: true), false);
    controller.release();
    controller.criticalFlows--;
  });
  test('tests use Google demo units; owner production IDs remain exact', () {
    expect(AdConstants.testAds, true);
    expect(AdConstants.rewarded, startsWith('ca-app-pub-3940256099942544/'));
    expect(AdConstants.productionRewarded, 'ca-app-pub-6633902647647422/6209750271');
    expect(AdConstants.productionInterstitial, 'ca-app-pub-6633902647647422/7522831942');
    expect(AdConstants.productionAppOpen, 'ca-app-pub-6633902647647422/7426718311');
    expect(AdConstants.productionBanner, 'ca-app-pub-6633902647647422/8835913618');
  });
}
