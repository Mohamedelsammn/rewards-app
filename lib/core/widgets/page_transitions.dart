import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The onboarding slide-and-fade used between Email → OTP → Password →
/// Character. Honors "remove animations".
CustomTransitionPage<void> onboardingPage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.disableAnimationsOf(context)) return child;
        final direction = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
        final enter = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        final leave = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInOutCubic);
        return FadeTransition(
          opacity: Tween<double>(begin: 1, end: .9).animate(leave),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: Offset(-.035 * direction, 0),
            ).animate(leave),
            child: FadeTransition(
              opacity: enter,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(.055 * direction, 0),
                  end: Offset.zero,
                ).animate(enter),
                child: child,
              ),
            ),
          ),
        );
      },
    );
