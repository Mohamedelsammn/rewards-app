import 'dart:async';
import 'dart:ui' show AppLifecycleState;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/app/startup/animated_splash.dart';
import 'package:rewardsapp/app/startup/startup_ads.dart';
import 'package:rewardsapp/core/services/ads/ads_launch_store.dart';
import 'package:rewardsapp/core/services/ads/app_open_ad_manager.dart';
import 'package:rewardsapp/core/services/ads/fullscreen_ad.dart';
import 'package:rewardsapp/core/services/ads/fullscreen_ad_gate.dart';
import 'package:rewardsapp/core/services/ads/giveaway_interstitial_pacer.dart';

class _Clock {
  DateTime now = DateTime(2026, 10, 22, 12);
  void advance(Duration d) => now = now.add(d);
}

class _Ad implements FullscreenAd {
  _Ad(this.loader);

  final _Loader loader;
  bool disposed = false;

  @override
  Future<bool> show() async {
    loader.shown++;
    loader.showing = true;
    await loader.dismiss?.future;
    loader.showing = false;
    return loader.showSucceeds;
  }

  @override
  void dispose() => disposed = true;
}

class _Loader implements FullscreenAdLoader {
  bool fill = true;
  bool showSucceeds = true;
  int loads = 0;
  int shown = 0;
  bool showing = false;

  /// When set, a shown ad stays up until it completes.
  Completer<void>? dismiss;

  @override
  Future<FullscreenAd?> load(FullscreenAdFormat format, String adUnitId) async {
    loads++;
    return fill ? _Ad(this) : null;
  }
}

PreloadedAdSlot _slot(_Loader loader, _Clock clock, {Duration maxAge = const Duration(hours: 1)}) =>
    PreloadedAdSlot(
      format: FullscreenAdFormat.interstitial,
      adUnitId: 'test-unit',
      loader: loader,
      maxAge: maxAge,
      clock: () => clock.now,
      retryDelays: const [Duration(milliseconds: 1)],
    );

void main() {
  late _Clock clock;
  late _Loader loader;
  late FullscreenAdGate gate;

  setUp(() {
    clock = _Clock();
    loader = _Loader();
    gate = FullscreenAdGate(clock: () => clock.now);
  });

  group('FullscreenAdGate', () {
    test('one fullscreen ad at a time', () async {
      final up = Completer<void>();
      final first = gate.run(() => up.future);
      expect(gate.showing, isTrue);
      expect(await gate.run(() async => 'second'), isNull, reason: 'refused while one shows');
      up.complete();
      await first;
      expect(gate.showing, isFalse);
    });

    test('automatic ads wait for the gap after the last one', () async {
      expect(gate.allows(const Duration(minutes: 2)), isTrue);
      await gate.run(() async {});
      expect(gate.allows(const Duration(minutes: 2)), isFalse);
      clock.advance(const Duration(minutes: 2));
      expect(gate.allows(const Duration(minutes: 2)), isTrue);
    });
  });

  group('PreloadedAdSlot', () {
    test('expires old ads and loads once at a time', () async {
      final slot = _slot(loader, clock);
      await Future.wait([slot.preload(), slot.preload()]);
      expect(loader.loads, 1);
      expect(slot.isReady, isTrue);
      clock.advance(const Duration(hours: 1));
      expect(slot.isReady, isFalse, reason: 'interstitials expire after an hour');
      slot.dispose();
    });

    test('a failed load retries', () async {
      loader.fill = false;
      final slot = _slot(loader, clock);
      await slot.preload();
      expect(slot.isReady, isFalse);
      loader.fill = true;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(loader.loads, greaterThanOrEqualTo(2));
      expect(slot.isReady, isTrue);
      slot.dispose();
    });

    test('a unit-less format stays off', () async {
      final slot = PreloadedAdSlot(
        format: FullscreenAdFormat.appOpen,
        adUnitId: '',
        loader: loader,
        maxAge: const Duration(hours: 4),
      );
      await slot.preload();
      expect(slot.enabled, isFalse);
      expect(loader.loads, 0);
    });
  });

  group('GiveawayInterstitialPacer', () {
    late GiveawayInterstitialPacer pacer;

    setUp(() {
      pacer = GiveawayInterstitialPacer(slot: _slot(loader, clock), gate: gate);
    });

    test('first and second openings: no ad; third: the ad; then every third', () async {
      pacer.preload();
      await Future<void>.delayed(Duration.zero);
      expect(await pacer.beforeOpening(), isTrue);
      expect(await pacer.beforeOpening(), isTrue);
      expect(loader.shown, 0);
      expect(await pacer.beforeOpening(), isTrue);
      expect(loader.shown, 1);

      clock.advance(const Duration(minutes: 3));
      await Future<void>.delayed(Duration.zero);
      await pacer.beforeOpening();
      await pacer.beforeOpening();
      expect(loader.shown, 1);
      await pacer.beforeOpening();
      expect(loader.shown, 2, reason: 'sixth opening');
    });

    test('an unavailable ad never blocks navigation', () async {
      loader.fill = false;
      for (var i = 0; i < 3; i++) {
        expect(await pacer.beforeOpening(), isTrue);
      }
      expect(loader.shown, 0);
      expect(pacer.openings, 3);
    });

    test('respects the gap after another fullscreen ad', () async {
      pacer.preload();
      await Future<void>.delayed(Duration.zero);
      await gate.run(() async {}); // e.g. an App Open ad just ended
      for (var i = 0; i < 3; i++) {
        await pacer.beforeOpening();
      }
      expect(loader.shown, 0);
    });

    test('a tap during an opening in progress is ignored (no double count)', () async {
      pacer.preload();
      await Future<void>.delayed(Duration.zero);
      await pacer.beforeOpening();
      await pacer.beforeOpening();
      loader.dismiss = Completer<void>();
      final third = pacer.beforeOpening();
      await Future<void>.delayed(Duration.zero);
      expect(loader.showing, isTrue);
      expect(await pacer.beforeOpening(), isFalse, reason: 'second tap while the ad is up');
      loader.dismiss!.complete();
      expect(await third, isTrue);
      expect(pacer.openings, 3);
    });

    test('the next ad is preloaded after dismissal', () async {
      pacer.preload();
      await Future<void>.delayed(Duration.zero);
      for (var i = 0; i < 3; i++) {
        await pacer.beforeOpening();
      }
      await Future<void>.delayed(Duration.zero);
      expect(loader.loads, 2);
    });
  });

  group('AppOpenAdManager', () {
    late AppOpenAdManager appOpen;

    setUp(() {
      appOpen = AppOpenAdManager(
        slot: _slot(loader, clock, maxAge: const Duration(hours: 4)),
        gate: gate,
        policy: const AppOpenPolicy(startupWait: Duration(milliseconds: 50)),
      );
    });

    Future<bool> backgroundFor(Duration away, {bool eligible = true}) async {
      await appOpen.onLifecycle(AppLifecycleState.paused, eligibleScreen: eligible);
      clock.advance(away);
      return appOpen.onLifecycle(AppLifecycleState.resumed, eligibleScreen: eligible);
    }

    test('startup shows a ready ad; none ready → no wait beyond the budget', () async {
      expect(await appOpen.showOnStartup(), isTrue);
      loader.fill = false;
      final timer = Stopwatch()..start();
      clock.advance(const Duration(hours: 1));
      appOpen.slot.dispose();
      final other = AppOpenAdManager(
        slot: _slot(loader, clock),
        gate: gate,
        policy: const AppOpenPolicy(startupWait: Duration(milliseconds: 50)),
      );
      expect(await other.showOnStartup(), isFalse);
      expect(timer.elapsed, lessThan(const Duration(seconds: 1)));
    });

    test('returning from the background to a main tab shows one', () async {
      appOpen.preload();
      await Future<void>.delayed(Duration.zero);
      expect(await backgroundFor(const Duration(minutes: 1)), isTrue);
    });

    test('short trips away, other screens and quick repeats show none', () async {
      appOpen.preload();
      await Future<void>.delayed(Duration.zero);
      expect(await backgroundFor(const Duration(seconds: 5)), isFalse, reason: 'too short');
      expect(
        await backgroundFor(const Duration(minutes: 1), eligible: false),
        isFalse,
        reason: 'login, onboarding, details…',
      );
      expect(await backgroundFor(const Duration(minutes: 1)), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(await backgroundFor(const Duration(minutes: 3)), isFalse, reason: 'frequency cap');
    });

    test('never when returning from an ad, or right after one', () async {
      appOpen.preload();
      await Future<void>.delayed(Duration.zero);
      // The user clicked a fullscreen ad and left the app from it.
      loader.dismiss = Completer<void>();
      final interstitial = gate.run(() => loader.dismiss!.future);
      await appOpen.onLifecycle(AppLifecycleState.paused, eligibleScreen: true);
      clock.advance(const Duration(minutes: 1));
      loader.dismiss!.complete();
      await interstitial;
      expect(await appOpen.onLifecycle(AppLifecycleState.resumed, eligibleScreen: true), isFalse);
      expect(await backgroundFor(const Duration(seconds: 40)), isFalse, reason: 'gap after an ad');
    });
  });

  group('StartupAdCoordinator', () {
    late AppOpenAdManager appOpen;

    setUp(() {
      splashIntroDone.value = true;
      startupAdDone.value = true;
      appOpen = AppOpenAdManager(
        slot: _slot(loader, clock, maxAge: const Duration(hours: 4)),
        gate: gate,
        policy: const AppOpenPolicy(startupWait: Duration(milliseconds: 50)),
      );
    });

    StartupAdCoordinator coordinator({
      required int previousLaunches,
      required bool? Function() destination,
      List<Stream<Object?>> changes = const [],
    }) {
      FlutterSecureStorage.setMockInitialValues({'ads_launch_count': '$previousLaunches'});
      return StartupAdCoordinator(
        appOpen: appOpen,
        launches: AdsLaunchStore(),
        warmUp: () async => appOpen.preload(),
        destination: destination,
        changes: changes,
        decisionTimeout: const Duration(milliseconds: 100),
      );
    }

    test('never on the very first launch', () async {
      await coordinator(previousLaunches: 0, destination: () => true).run();
      expect(loader.shown, 0);
      expect(startupAdDone.value, isTrue);
    });

    test('a returning, signed-in user sees it before Home', () async {
      final run = coordinator(previousLaunches: 3, destination: () => true).run();
      expect(startupAdDone.value, isFalse, reason: 'the splash is held');
      await run;
      expect(loader.shown, 1);
      expect(startupAdDone.value, isTrue);
    });

    test('signed out, maintenance or update: no ad, splash released', () async {
      await coordinator(previousLaunches: 3, destination: () => false).run();
      expect(loader.shown, 0);
      expect(startupAdDone.value, isTrue);
    });

    test('waits for the session, then decides', () async {
      bool? destination;
      final changes = StreamController<Object?>.broadcast();
      final run = coordinator(
        previousLaunches: 1,
        destination: () => destination,
        changes: [changes.stream],
      ).run();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      destination = true;
      changes.add(null);
      await run;
      expect(loader.shown, 1);
      await changes.close();
    });

    test('an unavailable ad never blocks startup', () async {
      loader.fill = false;
      await coordinator(previousLaunches: 3, destination: () => true).run();
      expect(loader.shown, 0);
      expect(startupAdDone.value, isTrue);
    });
  });
}
