import 'package:flutter/material.dart';

import '../localization/l10n.dart';
import '../theme/app_colors.dart';

/// Back button plus the animated onboarding progress (steps 0–3).
class AuthTop extends StatelessWidget {
  const AuthTop({this.step = -1, super.key});

  final int step;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.filledTonal(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => Navigator.of(context).maybePop(),
        // Material arrows mirror themselves in RTL.
        icon: const Icon(Icons.arrow_back),
      ),
      const Spacer(),
      if (step >= 0)
        Hero(
          tag: 'onboarding-progress',
          flightShuttleBuilder: (_, animation, _, fromContext, toContext) {
            final start = ((fromContext.widget as Hero).child as OnboardingProgress).step;
            final end = ((toContext.widget as Hero).child as OnboardingProgress).step;
            return AnimatedBuilder(
              animation: animation,
              builder: (_, _) => OnboardingProgress(
                step: start + (end - start) * Curves.easeInOutCubic.transform(animation.value),
              ),
            );
          },
          child: OnboardingProgress(step: step.toDouble()),
        ),
      const Spacer(),
      const SizedBox(width: 48),
    ],
  );
}

/// Three narrow capsules separated by two circular marks.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({required this.step, super.key});

  final double step;

  @override
  Widget build(BuildContext context) {
    final marks = <(double, bool)>[(0, false), (0, true), (1, false), (2, true), (3, false)];
    return Semantics(
      label: context.l10n.onboardingStep(step.round() + 1, 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < marks.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color.lerp(
                  AppColors.progressInactive,
                  AppColors.violet,
                  (step - marks[i].$1 + 1).clamp(0.0, 1.0),
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: SizedBox(width: marks[i].$2 ? 8 : 31, height: marks[i].$2 ? 8 : 5),
            ),
          ],
        ],
      ),
    );
  }
}
