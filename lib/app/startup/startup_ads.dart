import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/services/ad_diagnostics.dart';
import '../../core/services/ads/ads_launch_store.dart';
import '../../core/services/ads/app_open_ad_manager.dart';
import 'animated_splash.dart';

/// `false` while the cold-start App Open ad may still play; the router keeps
/// the splash until then, so Home only becomes interactive after the ad.
final startupAdDone = ValueNotifier<bool>(true);

/// Decides the cold-start App Open ad: never on the first launch, only when
/// the splash is about to open Home for a signed-in user, and never holding
/// the splash longer than the ad's short loading budget.
class StartupAdCoordinator {
  StartupAdCoordinator({
    required this.appOpen,
    required this.launches,
    required this.warmUp,
    required this.destination,
    required this.changes,
    this.decisionTimeout = const Duration(seconds: 6),
  });

  final AppOpenAdManager appOpen;
  final AdsLaunchStore launches;
  final Future<void> Function() warmUp;

  /// Where the splash would go now: `true` = Home (signed in), `false` =
  /// elsewhere (welcome, maintenance, update, offline), `null` = undecided.
  final bool? Function() destination;

  /// Config and session state changes.
  final List<Stream<Object?>> changes;

  /// Upper bound for config and session to settle.
  final Duration decisionTimeout;

  Future<void> run() async {
    if (!appOpen.enabled) return;
    // Hold the splash right away; released below in every case.
    startupAdDone.value = false;
    try {
      final previousLaunches = await launches.recordLaunch();
      adLog('appOpen startup: launch #${previousLaunches + 1}');
      if (previousLaunches == 0) {
        adLog('appOpen startup: first launch, no ad');
        return;
      }
      unawaited(warmUp());
      await _introPlayed();
      if (await _goingHome() != true) {
        adLog('appOpen startup: not opening Home, no ad');
        return;
      }
      await appOpen.showOnStartup();
    } catch (error) {
      adLog('appOpen startup failed ${error.runtimeType}');
    } finally {
      startupAdDone.value = true;
    }
  }

  Future<void> _introPlayed() async {
    if (splashIntroDone.value) return;
    final done = Completer<void>();
    void listener() {
      if (splashIntroDone.value && !done.isCompleted) done.complete();
    }

    splashIntroDone.addListener(listener);
    try {
      await done.future.timeout(decisionTimeout, onTimeout: () {});
    } finally {
      splashIntroDone.removeListener(listener);
    }
  }

  Future<bool?> _goingHome() async {
    if (destination() case final decided?) return decided;
    final settled = Completer<void>();
    final subscriptions = [
      for (final stream in changes)
        stream.listen((_) {
          if (destination() != null && !settled.isCompleted) settled.complete();
        }),
    ];
    try {
      await settled.future.timeout(decisionTimeout, onTimeout: () {});
    } finally {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    }
    return destination();
  }
}
