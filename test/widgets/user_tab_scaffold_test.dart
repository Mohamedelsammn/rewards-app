import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/services/ads/ad_service.dart';
import 'package:rewardsapp/services/cache/cache_service.dart';
import 'package:rewardsapp/shared/widgets/ad_banner.dart';
import 'package:rewardsapp/shared/widgets/app_bottom_nav.dart';
import 'package:rewardsapp/shared/widgets/user_tab_scaffold.dart';

class _Cache extends Mock implements CacheService {}

class _Tabs extends StatefulWidget {
  const _Tabs(this.ads);
  final AdService ads;
  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> {
  int index = 0;
  @override
  Widget build(BuildContext context) => UserTabScaffold(
    body: IndexedStack(
      index: index,
      children: const [
        Center(child: TextField()),
        Center(child: Text('My Giveaways')),
        Center(child: Text('Settings')),
      ],
    ),
    banner: AdaptiveAdBanner(ads: widget.ads),
    navigation: AppBottomNav(
      docked: true,
      selectedIndex: index,
      onTabSelected: (i) => setState(() => index = i),
      items: const [
        AppBottomNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          semanticLabel: 'Home',
        ),
        AppBottomNavItem(
          icon: Icons.card_giftcard_outlined,
          activeIcon: Icons.card_giftcard_rounded,
          semanticLabel: 'My Giveaways',
        ),
        AppBottomNavItem(
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings_rounded,
          semanticLabel: 'Settings',
        ),
      ],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late AdService ads;
  late List<MethodCall> calls;
  var requestedHeight = 50;
  Future<void> event(String name, [Map<String, dynamic> extra = const {}]) async {
    final id = (calls.lastWhere((c) => c.method == 'loadBannerAd').arguments as Map)['adId'];
    await messenger.handlePlatformMessage(
      instanceManager.channel.name,
      instanceManager.channel.codec.encodeMethodCall(
        MethodCall('onAdEvent', {'adId': id, 'eventName': name, ...extra}),
      ),
      (_) {},
    );
  }

  setUp(() {
    calls = [];
    requestedHeight = 50;
    messenger.setMockMethodCallHandler(instanceManager.channel, (call) async {
      calls.add(call);
      if (call.method.contains('AdaptiveBannerAdSize')) return requestedHeight;
      if (call.method == 'getAdSize') return const AdSize(width: 320, height: 50);
      return null;
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (_) async => null);
    ads = AdService(_Cache())
      ..sessionActive = true
      ..ready = true;
  });
  tearDown(() async {
    ads.dispose();
    await Future<void>.delayed(Duration.zero);
    messenger.setMockMethodCallHandler(instanceManager.channel, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
  });

  Future<void> mount(WidgetTester tester, double width, TextDirection direction) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 820);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(textDirection: direction, child: _Tabs(ads)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  for (final width in [320.0, 360.0, 393.0, 430.0, 600.0]) {
    for (final direction in TextDirection.values) {
      testWidgets('loaded banner directly touches pill at $width $direction on all tabs', (
        tester,
      ) async {
        await mount(tester, width, direction);
        await event('onAdLoaded');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final originalAdWidget = tester.widget<AdWidget>(find.byType(AdWidget));
        final originalAdState = tester.state(find.byType(AdWidget));
        for (final tab in ['Home', 'My Giveaways', 'Settings']) {
          if (tab != 'Home') {
            await tester.tap(
              find.byIcon(
                tab == 'Settings' ? Icons.settings_outlined : Icons.card_giftcard_outlined,
              ),
            );
          }
          await tester.pump(const Duration(milliseconds: 500));
          final banner = tester.getRect(find.byType(AdWidget));
          final pill = tester.getRect(find.byKey(const ValueKey('glass_bottom_bar_tab_pill')));
          expect(banner.height, 50);
          expect(banner.bottom, closeTo(pill.top, .01));
          expect(pill.bottom, closeTo(820 - 24 - 20, .01));
          expect(tester.widget<AdWidget>(find.byType(AdWidget)), same(originalAdWidget));
          expect(tester.state(find.byType(AdWidget)), same(originalAdState));
          expect(
            find.ancestor(
              of: find.byType(AdWidget),
              matching: find.byType(AdaptiveLiquidGlassLayer),
            ),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        }
        expect(calls.where((c) => c.method == 'loadBannerAd'), hasLength(1));
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('pending/failed banner reserves zero height and does not retry on tab switches', (
    tester,
  ) async {
    await mount(tester, 320, TextDirection.rtl);
    final dock = find.byKey(const ValueKey('user-bottom-dock'));
    expect(tester.getSize(dock).height, 78);
    await event('onAdFailedToLoad', {'loadAdError': LoadAdError(3, 'test', 'no fill', null)});
    await tester.pump();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getSize(dock).height, 78);
    expect(find.byType(AdWidget), findsNothing);
    expect(calls.where((c) => c.method == 'loadBannerAd'), hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    ads.endUserSession();
  });

  testWidgets('keyboard hides dock without remounting or reloading the banner', (tester) async {
    await mount(tester, 360, TextDirection.ltr);
    await event('onAdLoaded');
    await tester.pump();
    final original = tester.state(find.byType(AdWidget));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();
    expect(find.byType(AdWidget), findsNothing);
    expect(tester.takeException(), isNull);
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();
    expect(tester.state(find.byType(AdWidget)), same(original));
    expect(calls.where((c) => c.method == 'loadBannerAd'), hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('SDK resolved size replaces a taller adaptive request with no creative gap', (
    tester,
  ) async {
    requestedHeight = 128;
    await mount(tester, 320, TextDirection.ltr);
    expect(ads.banner!.size.height, 128);
    await event('onAdLoaded');
    await tester.pump();
    expect(ads.bannerSize!.height, 50);
    final ad = tester.getRect(find.byType(AdWidget));
    final pill = tester.getRect(find.byKey(const ValueKey('glass_bottom_bar_tab_pill')));
    expect(ad.height, 50);
    expect(ad.bottom, closeTo(pill.top, .01));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('width changes unmount the disposed banner while its replacement loads', (
    tester,
  ) async {
    await mount(tester, 360, TextDirection.rtl);
    await event('onAdLoaded');
    await tester.pump();
    final oldWidget = tester.widget<AdWidget>(find.byType(AdWidget));
    tester.view.physicalSize = const Size(320, 820);
    await tester.pump();
    await tester.pump();
    expect(find.byType(AdWidget), findsNothing);
    expect(tester.getSize(find.byKey(const ValueKey('user-bottom-dock'))).height, 78);
    await event('onAdLoaded');
    await tester.pump();
    expect(tester.widget<AdWidget>(find.byType(AdWidget)), isNot(same(oldWidget)));
    expect(calls.where((c) => c.method == 'loadBannerAd'), hasLength(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
