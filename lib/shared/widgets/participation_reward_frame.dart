import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A cosmetic, account-bound frame for a server-verified rewarded entry.
class ParticipationRewardFrame extends StatelessWidget {
  const ParticipationRewardFrame({
    super.key,
    required this.enabled,
    required this.child,
    this.borderRadius = 16,
  });

  final bool enabled;
  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.goldAccent, width: 2),
        boxShadow: [BoxShadow(color: AppColors.goldAccent.withValues(alpha: 0.22), blurRadius: 9)],
      ),
      child: child,
    );
  }
}
