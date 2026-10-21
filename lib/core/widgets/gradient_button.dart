import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The redesign's 62 dp pill CTA with the violet (or dark) gradient.
class GradientButton extends StatelessWidget {
  const GradientButton(
    this.label, {
    required this.onPressed,
    this.icon = Icons.arrow_forward,
    this.dark = false,
    this.leadingIcon = false,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool dark;
  final bool leadingIcon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final glyph = busy
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
          )
        : Icon(icon, color: Colors.white);
    return Opacity(
      opacity: onPressed == null && !busy ? .55 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: dark ? AppGradients.darkButton : AppGradients.primaryButton,
          borderRadius: BorderRadius.circular(AppRadii.button),
          boxShadow: AppShadows.button,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 62,
          child: TextButton(
            onPressed: busy ? null : onPressed,
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leadingIcon) ...[glyph, const SizedBox(width: 14)],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.buttonLabel,
                  ),
                ),
                if (!leadingIcon) ...[const SizedBox(width: 14), glyph],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
