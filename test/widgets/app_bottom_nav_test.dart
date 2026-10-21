import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:rewardsapp/core/theme/app_colors.dart';
import 'package:rewardsapp/shared/widgets/app_bottom_nav.dart';

void main() {
  final items = [
    const AppBottomNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      semanticLabel: 'Home',
    ),
    const AppBottomNavItem(
      icon: Icons.card_giftcard_outlined,
      activeIcon: Icons.card_giftcard_rounded,
      semanticLabel: 'My Giveaways',
    ),
    const AppBottomNavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      semanticLabel: 'Settings',
    ),
  ];

  testWidgets('renders every destination, including the selected one\'s active icon variant', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(items: items, selectedIndex: 1, onTabSelected: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.card_giftcard_rounded), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });

  // Regression test for the "nav shrinks to a small left-aligned blob on
  // wide screens" bug: a fixed `tabWidth` made the visible glass pill only
  // `tabWidth * tabCount` wide and left-anchored at offset 0, instead of
  // spanning/centering across the available width. With `tabWidth: null`
  // (the fix), tab items are evenly distributed across the full width the
  // parent gives the bar, so the last tab's icon should land near the
  // right edge of a wide viewport, not clustered in the leftmost fraction.
  testWidgets('spans the available width instead of shrinking to the left on a wide screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(items: items, selectedIndex: 0, onTabSelected: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final lastIconCenter = tester.getCenter(find.byIcon(Icons.settings_outlined));
    // The bar has its own internal horizontal margins, so this isn't a tight
    // bound -- it only needs to rule out the "shrunk into the left ~15%"
    // failure mode the bug produced.
    expect(lastIconCenter.dx, greaterThan(600));
  });

  // Regression test for the "selected pill briefly flashes white during a
  // tab switch" bug: the package renders the selected indicator in two
  // passes -- a solid `indicatorColor` pill at rest, and a separate
  // liquid-glass lens (with its own independent, transparent-white base
  // tint) during the tap/drag morph animation. Without an explicit
  // `indicatorSettings.glassColor`, that morph phase reads as white/
  // translucent instead of blue. This asserts the fix is wired up: the
  // glass lens itself is tinted to match the app's primary blue.
  testWidgets('tints the liquid-glass morph indicator blue so it never flashes white', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(items: items, selectedIndex: 0, onTabSelected: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final glassTabBar = tester.widget<GlassTabBar>(find.byType(GlassTabBar));
    final glassColor = glassTabBar.indicatorSettings?.glassColor;

    expect(glassColor, isNotNull);
    expect(glassColor!.a, greaterThan(0), reason: 'must not be fully transparent (reads as white)');
    expect(glassColor.r, closeTo(AppColors.primary.r, 0.01));
    expect(glassColor.g, closeTo(AppColors.primary.g, 0.01));
    expect(glassColor.b, closeTo(AppColors.primary.b, 0.01));
  });

  testWidgets('tapping a destination reports its index', (tester) async {
    int? tappedIndex;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(
            items: items,
            selectedIndex: 0,
            onTabSelected: (i) => tappedIndex = i,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(tappedIndex, 2);
  });
}
