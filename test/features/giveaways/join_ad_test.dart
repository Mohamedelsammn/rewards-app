import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewardsapp/app/di/injection_container.dart';
import 'package:rewardsapp/app/router/routes.dart';
import 'package:rewardsapp/core/error/app_exception.dart';
import 'package:rewardsapp/core/localization/l10n.dart';
import 'package:rewardsapp/core/localization/localized_text.dart';
import 'package:rewardsapp/core/services/admob_service.dart';
import 'package:rewardsapp/core/services/ads/ads_manager.dart';
import 'package:rewardsapp/core/services/ads/fullscreen_ad.dart';
import 'package:rewardsapp/core/services/ads/fullscreen_ad_gate.dart';
import 'package:rewardsapp/core/theme/app_theme.dart';
import 'package:rewardsapp/features/giveaways/domain/entities/giveaway_entities.dart';
import 'package:rewardsapp/features/giveaways/domain/repositories/giveaways_repository.dart';
import 'package:rewardsapp/features/giveaways/presentation/giveaway_navigation.dart';
import 'package:rewardsapp/features/giveaways/presentation/join_ad/giveaway_join_ads.dart';
import 'package:rewardsapp/features/giveaways/presentation/pages/giveaway_details_page.dart';
import 'package:rewardsapp/features/giveaways/presentation/pages/ticket_page.dart';

const _giveaway = Giveaway(
  id: 'g1',
  title: LocalizedText(en: 'Win an iPhone 15 Pro', ar: 'اربح آيفون 15 برو'),
  status: GiveawayStatus.active,
);

class _Ads {
  RewardedAdOutcome outcome = RewardedAdOutcome.completed;
  int shown = 0;
  Completer<void>? hold;
  Future<RewardedAdOutcome> show({required String adUnitId}) async {
    shown++;
    await hold?.future;
    return outcome;
  }
}

GiveawayJoinAds _joinAds(_Ads ads, {bool feature = true, String unit = 'test-unit'}) =>
    GiveawayJoinAds(show: ads.show, featureEnabled: feature, adUnitId: unit);

class _Giveaways implements GiveawaysRepository {
  int entered = 0;

  /// The entry API refuses (e.g. the giveaway filled up meanwhile).
  bool full = false;

  @override
  Future<GiveawayDetails> details(String id) async => const GiveawayDetails(giveaway: _giveaway);

  @override
  Future<GiveawayEntry> enter(String giveawayId) async {
    entered++;
    if (full) throw const AppException(code: 'GIVEAWAY_FULL', statusCode: 409);
    return const GiveawayEntry(
      id: 'e1',
      giveawayId: 'g1',
      participationNumber: '123456',
      active: true,
    );
  }

  @override
  Future<List<GiveawayWinner>?> results(String giveawayId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Widget _app(GoRouter router, {Locale locale = const Locale('en')}) => MaterialApp.router(
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  routerConfig: router,
);

GoRouter _detailsRouter() => GoRouter(
  initialLocation: '/details',
  routes: [
    GoRoute(
      path: '/details',
      builder: (_, _) => const GiveawayDetailsPage(giveawayId: 'g1'),
    ),
    GoRoute(
      path: Routes.ticket,
      builder: (_, state) => Scaffold(body: Text('TICKET ${(state.extra! as TicketArgs).number}')),
    ),
  ],
);

void main() {
  group('GiveawayJoinAds', () {
    test('off by default (AdMob policy); kill switch and unit-less off', () {
      final ads = _Ads();
      expect(
        GiveawayJoinAds(show: ads.show).requiresAd(_giveaway),
        isFalse,
        reason: 'ADS_JOIN_GIVEAWAY defaults to off: joining never requires an ad',
      );
      expect(_joinAds(ads, feature: false).requiresAd(_giveaway), isFalse);
      expect(
        _joinAds(ads, unit: '').requiresAd(_giveaway),
        isFalse,
        reason: 'a build without a rewarded unit',
      );
      expect(_joinAds(ads).requiresAd(_giveaway), isTrue);
      const upcoming = Giveaway(
        id: 'g2',
        title: LocalizedText(en: 'Soon'),
        status: GiveawayStatus.upcoming,
      );
      expect(_joinAds(ads).requiresAd(upcoming), isFalse);
    });

    test('the reward callback, not dismissal, makes the user eligible', () async {
      final ads = _Ads();
      expect(await _joinAds(ads).watch(_giveaway), JoinAdOutcome.rewardEarned);
    });

    test('skipped, unavailable and failed ads', () async {
      final ads = _Ads();
      final join = _joinAds(ads);
      ads.outcome = RewardedAdOutcome.dismissedEarly;
      expect(await join.watch(_giveaway), JoinAdOutcome.skipped);
      ads.outcome = RewardedAdOutcome.failedToLoad;
      expect(await join.watch(_giveaway), JoinAdOutcome.unavailable);
      ads.outcome = RewardedAdOutcome.failedToShow;
      expect(await join.watch(_giveaway), JoinAdOutcome.failed);
    });

    test('a second watch while one runs is refused', () async {
      final ads = _Ads()..hold = Completer<void>();
      final join = _joinAds(ads);
      final first = join.watch(_giveaway);
      expect(await join.watch(_giveaway), JoinAdOutcome.failed);
      ads.hold!.complete();
      expect(await first, JoinAdOutcome.rewardEarned);
      expect(ads.shown, 1);
    });
  });

  group('Join Giveaway with an ad', () {
    late _Giveaways repository;
    late _Ads ads;

    setUp(() async {
      final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 2.625;
      addTearDown(view.reset);
      repository = _Giveaways();
      ads = _Ads();
      await sl.reset();
      sl
        ..registerSingleton<GiveawaysRepository>(repository)
        ..registerSingleton<GiveawayJoinAds>(_joinAds(ads));
    });

    Future<void> tapJoin(WidgetTester tester, String label) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    testWidgets('Cancel: no ad, no entry', (tester) async {
      await tester.pumpWidget(_app(_detailsRouter()));
      await tester.pumpAndSettle();
      await tapJoin(tester, 'Join Giveaway');
      expect(find.text('Watch an Ad to Join'), findsOneWidget);
      expect(
        find.text('Watch a short advertisement to continue joining this giveaway.'),
        findsOneWidget,
      );
      expect(find.text('Watch Ad'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(ads.shown, 0);
      expect(repository.entered, 0);
    });

    testWidgets('reward earned: joins with the existing API', (tester) async {
      await tester.pumpWidget(_app(_detailsRouter()));
      await tester.pumpAndSettle();
      await tapJoin(tester, 'Join Giveaway');
      await tester.tap(find.text('Watch Ad'));
      await tester.pumpAndSettle();
      expect(ads.shown, 1);
      expect(repository.entered, 1);
      // The existing participation-number screen, with the server's number.
      expect(find.text('TICKET 123456'), findsOneWidget);
    });

    testWidgets('closing the ad early does not join', (tester) async {
      ads.outcome = RewardedAdOutcome.dismissedEarly;
      await tester.pumpWidget(_app(_detailsRouter()));
      await tester.pumpAndSettle();
      await tapJoin(tester, 'Join Giveaway');
      await tester.tap(find.text('Watch Ad'));
      await tester.pumpAndSettle();
      expect(repository.entered, 0);
      expect(find.text('Watch the full video to join.'), findsOneWidget);
    });

    testWidgets('Arabic dialog', (tester) async {
      await tester.pumpWidget(_app(_detailsRouter(), locale: const Locale('ar')));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold).first));
      await tapJoin(tester, l10n.giveawayJoin);
      expect(find.text('شاهد إعلانًا للمشاركة'), findsOneWidget);
      expect(find.text('يجب مشاهدة إعلان قصير قبل إكمال المشاركة في هذا السحب.'), findsOneWidget);
      expect(find.text('مشاهدة الإعلان'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text('شاهد إعلانًا للمشاركة'))),
        TextDirection.rtl,
      );
    });

    testWidgets('ad unavailable: localized message, no entry, can try again', (tester) async {
      ads.outcome = RewardedAdOutcome.failedToLoad;
      await tester.pumpWidget(_app(_detailsRouter()));
      await tester.pumpAndSettle();
      await tapJoin(tester, 'Join Giveaway');
      await tester.tap(find.text('Watch Ad'));
      await tester.pumpAndSettle();
      expect(repository.entered, 0);
      expect(find.text('No video is available right now. Try again later.'), findsOneWidget);

      ads.outcome = RewardedAdOutcome.completed;
      // The message clears; the user tries again.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tapJoin(tester, 'Join Giveaway');
      await tester.tap(find.text('Watch Ad'));
      await tester.pumpAndSettle();
      expect(ads.shown, 2);
      expect(repository.entered, 1);
    });

    testWidgets('ad failed to show: error, no entry', (tester) async {
      ads.outcome = RewardedAdOutcome.failedToShow;
      await tester.pumpWidget(_app(_detailsRouter()));
      await tester.pumpAndSettle();
      await tapJoin(tester, 'Join Giveaway');
      await tester.tap(find.text('Watch Ad'));
      await tester.pumpAndSettle();
      expect(repository.entered, 0);
      expect(find.text("The video couldn't be shown. Please try again."), findsOneWidget);
    });

    testWidgets('Join API fails after the reward: server error, no number', (tester) async {
      repository.full = true;
      await tester.pumpWidget(_app(_detailsRouter()));
      await tester.pumpAndSettle();
      await tapJoin(tester, 'Join Giveaway');
      await tester.tap(find.text('Watch Ad'));
      await tester.pumpAndSettle();
      expect(ads.shown, 1);
      expect(repository.entered, 1);
      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold).first));
      expect(find.text(l10n.errGiveawayFull), findsOneWidget);
      expect(find.textContaining('TICKET'), findsNothing);
    });

    testWidgets('repeated taps: one dialog, one ad, one entry', (tester) async {
      ads.hold = Completer<void>();
      await tester.pumpWidget(_app(_detailsRouter()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Join Giveaway'));
      await tester.tap(find.text('Join Giveaway'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Watch an Ad to Join'), findsOneWidget);
      await tester.tap(find.text('Watch Ad'));
      await tester.pump(const Duration(milliseconds: 500));
      // Let the dialog finish closing while the ad stays up.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(ads.shown, 1, reason: 'the rewarded ad started after consent');
      // While the ad is up, more taps on Join do nothing.
      await tester.tap(find.text('Join Giveaway'), warnIfMissed: false);
      await tester.pump();
      expect(find.text('Watch an Ad to Join'), findsNothing);
      ads.hold!.complete();
      await tester.pumpAndSettle();
      expect(ads.shown, 1);
      expect(repository.entered, 1);
    });

    testWidgets('flag off: Join works exactly as before', (tester) async {
      sl
        ..unregister<GiveawayJoinAds>()
        ..registerSingleton<GiveawayJoinAds>(_joinAds(ads, feature: false));
      await tester.pumpWidget(_app(_detailsRouter()));
      await tester.pumpAndSettle();
      await tapJoin(tester, 'Join Giveaway');
      expect(find.text('Watch an Ad to Join'), findsNothing);
      expect(repository.entered, 1);
    });
  });

  group('openGiveawayFromTap', () {
    late _InterstitialLoader loader;

    setUp(() async {
      loader = _InterstitialLoader();
      await sl.reset();
      sl
        ..registerSingleton<GiveawaysRepository>(_Giveaways())
        ..registerSingleton<AdsManager>(
          AdsManager(
            gate: FullscreenAdGate(),
            loader: loader,
            initializeSdk: () async {},
            appOpenUnit: '',
            interstitialUnit: 'test-unit',
          ),
        );
    });

    GoRouter listRouter() => GoRouter(
      initialLocation: '/list',
      routes: [
        GoRoute(
          path: '/list',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => openGiveawayFromTap(context, 'g1'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/giveaway/:id',
          builder: (_, _) => const Scaffold(body: Text('DETAILS')),
        ),
      ],
    );

    Future<void> openAndReturn(WidgetTester tester, GoRouter router) async {
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('DETAILS'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
    }

    testWidgets('third opening plays the interstitial at the transition', (tester) async {
      sl<AdsManager>().giveaways.preload();
      final router = listRouter();
      await tester.pumpWidget(_app(router));
      await openAndReturn(tester, router);
      await openAndReturn(tester, router);
      expect(loader.shown, 0);
      await openAndReturn(tester, router);
      expect(loader.shown, 1);
      sl<AdsManager>().dispose();
    });

    testWidgets('failing ads never block navigation (Arabic)', (tester) async {
      loader.fill = false;
      sl<AdsManager>().giveaways.preload();
      final router = listRouter();
      await tester.pumpWidget(_app(router, locale: const Locale('ar')));
      for (var i = 0; i < 3; i++) {
        await openAndReturn(tester, router);
      }
      expect(loader.shown, 0);
      sl<AdsManager>().dispose();
    });
  });
}

class _InterstitialLoader implements FullscreenAdLoader {
  bool fill = true;
  int shown = 0;

  @override
  Future<FullscreenAd?> load(FullscreenAdFormat format, String adUnitId) async =>
      fill ? _ShownAd(this) : null;
}

class _ShownAd implements FullscreenAd {
  _ShownAd(this.loader);

  final _InterstitialLoader loader;

  @override
  Future<bool> show() async {
    loader.shown++;
    return true;
  }

  @override
  void dispose() {}
}
