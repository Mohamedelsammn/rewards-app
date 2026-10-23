import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// Full-width Join Giveaway pill from the reference: purple-to-pink
/// gradient, white gift icon, bold label and a trailing chevron (mirrored in
/// RTL). Disabled states are dimmed and lose the glow; while [busy] it shows
/// a small progress mark and ignores taps.
class GiveawayJoinButton extends StatelessWidget {
  const GiveawayJoinButton({
    required this.label,
    required this.onPressed,
    this.icon = LucideIcons.gift500,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool busy;

  static const height = 58.0;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null && !busy ? .5 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppGradients.giveawayCta,
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: onPressed == null ? null : AppGradients.giveawayCtaShadow,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: const ValueKey('giveaway-cta'),
              borderRadius: BorderRadius.circular(height / 2),
              onTap: enabled ? onPressed : null,
              child: SizedBox(
                height: height,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 52),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (busy)
                            const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          else
                            Icon(icon, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PositionedDirectional(
                      end: 20,
                      child: Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
