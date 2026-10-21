import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_visuals.dart';

/// A titled, rounded card grouping related [SettingsRow]s -- the shared
/// "grouped settings" look used by both User Settings and Admin Profile so
/// there is exactly one grouped-settings implementation, not two that could
/// drift apart.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs, bottom: AppSpacing.sm),
          child: Text(
            title,
            style: AppTypography.labelSm.copyWith(fontSize: 11, letterSpacing: .6),
          ),
        ),
        // Shadow lives on a plain Container; the rounded, colored surface
        // itself is a Material (not a colored Container/DecoratedBox) so it
        // becomes the ListTiles' nearest Material ancestor -- a DecoratedBox
        // between a ListTile and its Material paints over the ink splash
        // effects, which Flutter flags as an error in debug/test builds.
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppVisuals.cardRadius),
            boxShadow: AppVisuals.cardShadow,
          ),
          child: Material(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppVisuals.cardRadius),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i != children.length - 1)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 64, end: 16),
                      child: const Divider(height: 1, color: AppVisuals.divider),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
    this.iconColor,
    this.labelColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final Color? iconColor;
  final Color? labelColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: AppVisuals.icon, color: iconColor ?? AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMd.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: labelColor ?? AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (trailing != null)
                Expanded(
                  child: Text(
                    trailing!,
                    textAlign: TextAlign.end,
                    style: AppTypography.bodyMd.copyWith(fontSize: 12),
                  ),
                ),
              const SizedBox(width: 4),
              Icon(AppIcons.next, size: 17, color: AppColors.outline),
            ],
          ),
        ),
      ),
    );
  }
}

/// Deliberately a plain, generic person glyph -- structured so a real
/// illustration/vector asset can replace [icon] here later without touching
/// any call site (User Settings, Admin Profile both use this).
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.radius = 32, this.icon = AppIcons.profile});

  final double radius;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.15),
      child: Icon(icon, size: radius, color: AppColors.primary),
    );
  }
}
