import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/theme/app_colors.dart';

/// One destination in [AppBottomNav].
class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.semanticLabel,
  });

  final IconData icon;
  final IconData activeIcon;

  /// Announced to screen readers. The bar is deliberately icon-only (no
  /// visible label -- see [AppBottomNav] doc comment), so this is the only
  /// place the destination's name exists for accessibility.
  final String semanticLabel;
}

/// The single Liquid Glass bottom navigation bar used by BOTH the User and
/// Admin shells. There must only ever be one visual definition of this
/// component -- User and Admin pass different [items]/[selectedIndex], but
/// never a different look.
///
/// Design decisions, and the bugs they fix:
/// - **Icons only, no labels.** [GlassTab.label] is left null; instead every
///   item carries a [AppBottomNavItem.semanticLabel] for accessibility only.
/// - **`tabWidth: null` (responsive, package-computed).** `GlassScaffold`
///   gives its `bottomBar` slot a `Positioned(left: 0, right: 0, ...)` --
///   i.e. the FULL available width. Internally, `GlassTabBar.bottom` derives
///   its visible glass pill's width from `resolveTabPillWidth(tabWidth,
///   tabCount, maxAvailable)`: `null` resolves to `maxAvailable` (fills the
///   width it was given); a fixed value resolves to `tabWidth * tabCount`
///   instead, and -- critically -- the package always left-anchors that
///   narrower pill at offset 0 with no centering logic of its own. A
///   previous pass set a fixed `tabWidth` (to square the per-tab selected
///   indicator into a circle) without realizing that value ALSO controls the
///   whole bar's rendered width, not just the indicator: on any screen wider
///   than `tabWidth * tabCount`, the entire glass surface -- not just the
///   indicator -- rendered small and flush against the left edge instead of
///   spanning/centering across the screen. That is a correctness bug (the
///   bar becomes hard to see/reach), so it takes priority over indicator
///   shape: `tabWidth: null` restores full, responsive, correctly-centered
///   width on every screen size. Trade-off: the per-tab selected indicator
///   is consequently a rounded rectangle sized to its (wider) tab cell
///   rather than a perfect circle -- an explicit, generous
///   [indicatorBorderRadius] keeps that rectangle reading as an intentional
///   rounded "pill" highlight rather than a distorted shape.
/// - **An explicit, tinted [LiquidGlassSettings.glassColor] with a real
///   alpha.** The package default is `Color.fromARGB(0, 255, 255, 255)` --
///   zero opacity -- which is why the bar previously read as an
///   "excessively transparent floating object" with no stable surface.
///   Giving it the app's own elevated-surface color at ~65% keeps the glass
///   refraction visible while giving the bar a real, designed background.
/// - **A solid, opaque [indicatorColor]** (was `Colors.transparent`,
///   meaning the selected pill had no fill at all) with a light icon color
///   on top for correct contrast.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTabSelected,
    this.docked = false,
  });

  final List<AppBottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  /// Remove only the outer top gap when directly following a banner. The
  /// existing pill geometry, bottom breathing room and animations are retained.
  final bool docked;

  static const double _barHeight = 58;
  static const double _indicatorBorderRadius = 24;

  /// `GlassTabBar.bottom`'s default vertical padding (top + bottom) around
  /// the pill -- not overridden above, so this must track the package
  /// default. Kept as a named constant (rather than repeating `20`) so
  /// [footprint] stays correct if either value ever changes.
  static const double _verticalPadding = 20;

  /// The bar's total on-screen footprint: how much vertical space any
  /// content/floating-element BELOW it (in z-order, i.e. behind the glass
  /// pill) must reserve so it is never covered.
  ///
  /// Mirrors exactly what `GlassScaffold` itself computes internally
  /// (`GlassTabBar.preferredSize.height` = `barHeight + verticalPadding * 2`,
  /// plus the device's bottom safe-area inset that `GlassScaffold` also
  /// pushes the bar up by). Single source of truth so callers never hardcode
  /// a device-specific offset -- see [AppBottomNav] doc comment.
  static double footprint(BuildContext context) {
    return _barHeight + (_verticalPadding * 2) + MediaQuery.paddingOf(context).bottom;
  }

  @override
  Widget build(BuildContext context) {
    final bar = GlassTabBar.bottom(
      verticalPadding: docked ? 0 : _verticalPadding,
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected,
      tabs: [
        for (final item in items)
          GlassTab(
            icon: Icon(item.icon),
            activeIcon: Icon(item.activeIcon),
            semanticLabel: item.semanticLabel,
          ),
      ],
      barHeight: _barHeight,
      indicatorBorderRadius: _indicatorBorderRadius,
      indicatorColor: AppColors.primary,
      selectedIconColor: AppColors.onPrimary,
      unselectedIconColor: AppColors.outline,
      glowOpacity: 0.3,
      // Fixes the "white flash" during tab switches: the package renders the
      // selected pill in two passes -- a solid DecoratedBox in `indicatorColor`
      // at rest, and a separate liquid-glass lens during the tap/drag morph
      // animation. That glass lens has its OWN base tint (transparent white)
      // completely independent of `indicatorColor`, so mid-transition the pill
      // visibly reads as white/translucent before settling back to solid blue.
      // Tinting the glass lens itself blue keeps the liquid-glass morph
      // animation (still refractive, still jelly-physics) while making every
      // frame of the transition read as blue, not just the resting frame.
      indicatorSettings: LiquidGlassSettings(glassColor: AppColors.primary.withValues(alpha: 0.85)),
      settings: LiquidGlassSettings(
        glassColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.65),
        blur: 10,
        thickness: 20,
        standardOpacityMultiplier: 1.0,
      ),
    );
    return docked
        ? Padding(
            padding: const EdgeInsets.only(bottom: _verticalPadding),
            child: bar,
          )
        : bar;
  }
}
