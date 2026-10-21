import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../core/theme/app_colors.dart';
import 'app_bottom_nav.dart';

/// The bottom dock participates in layout: no overlay footprint or guessed height.
/// Offstage keeps the banner mounted when the keyboard temporarily hides the dock.
class UserTabScaffold extends StatelessWidget {
  const UserTabScaffold({
    super.key,
    required this.body,
    required this.navigation,
    this.banner = const SizedBox.shrink(),
  });
  final Widget body;
  final AppBottomNav navigation;
  final Widget banner;

  @override
  Widget build(BuildContext context) => LiquidGlassScope(
    child: Scaffold(
      backgroundColor: AppColors.surface,
      body: GlassPage(
        background: const ColoredBox(color: AppColors.surface),
        child: body,
      ),
      bottomNavigationBar: Offstage(
        offstage: MediaQuery.viewInsetsOf(context).bottom > 0,
        child: SafeArea(
          top: false,
          child: Column(
            key: const ValueKey('user-bottom-dock'),
            mainAxisSize: MainAxisSize.min,
            // Native ads must remain outside the glass shader/filter layer.
            children: [
              banner,
              AdaptiveLiquidGlassLayer(child: navigation),
            ],
          ),
        ),
      ),
    ),
  );
}
