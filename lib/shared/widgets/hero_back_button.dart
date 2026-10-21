import 'package:flutter/material.dart';
import '../../core/theme/app_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// A circular back button meant to float over a hero image at the top of a
/// screen (e.g. Giveaway Details). Must be the direct child of a [Stack].
///
/// Fixes two real bugs the previous ad-hoc `Positioned(top: <fixed value>)`
/// version had:
///
/// - **Not SafeArea-aware.** A hardcoded top offset assumes one status-bar
///   height; on devices with a taller inset (camera cutouts, larger
///   notches), the button sat too close to -- sometimes partially under --
///   the system status area, which is also why it could feel unreliable to
///   tap. This version insets from the *actual* device
///   `MediaQuery.padding.top` via [SafeArea], so it always lands just below
///   the real system UI on every device.
/// - **Under the accessibility minimum tap target.** The icon-plus-padding
///   before was ~40x40 logical pixels; this is a fixed 44x44 box (the
///   Material/Apple-recommended minimum), so the whole visible circle is
///   reliably tappable, not just its visual center.
///
/// This is the single reusable implementation of this control -- any future
/// hero-image screen should use this rather than re-deriving its own
/// positioning.
class HeroBackButton extends StatelessWidget {
  const HeroBackButton({super.key, this.onTap});

  /// Defaults to popping the current route.
  final VoidCallback? onTap;

  static const double _tapTargetSize = 44;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: SafeArea(
        bottom: false,
        left: false,
        right: false,
        child: Align(
          // start/end (not left/right) so the button correctly lands in the
          // top-trailing-reading-direction corner under Arabic RTL too.
          alignment: AlignmentDirectional.topStart,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.md, AppSpacing.sm, 0, 0),
            child: Material(
              color: Colors.white.withValues(alpha: 0.9),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap ?? () => Navigator.of(context).maybePop(),
                child: const SizedBox(
                  width: _tapTargetSize,
                  height: _tapTargetSize,
                  child: Icon(AppIcons.back, color: AppColors.onSurface, size: 20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
