import 'package:flutter/material.dart';

/// Color tokens lifted directly from DESIGN.md (Lumina Rewards design system).
class AppColors {
  const AppColors._();

  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFDBD8E5);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF5F2FF);
  static const surfaceContainer = Color(0xFFEFECF9);
  static const surfaceContainerHigh = Color(0xFFE9E6F4);
  static const surfaceContainerHighest = Color(0xFFE4E1EE);

  static const onSurface = Color(0xFF1B1B24);
  static const onSurfaceVariant = Color(0xFF454555);
  static const inverseSurface = Color(0xFF302F39);
  static const inverseOnSurface = Color(0xFFF2EFFC);

  static const outline = Color(0xFF767587);
  static const outlineVariant = Color(0xFFC6C4D8);

  static const primary = Color(0xFF4042E1);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF5B5FFB);
  static const onPrimaryContainer = Color(0xFFFEFAFF);
  static const inversePrimary = Color(0xFFC0C1FF);

  static const secondary = Color(0xFF712AE2);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFF8A4CFC);
  static const onSecondaryContainer = Color(0xFFFFFBFF);

  static const tertiary = Color(0xFF964200);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFBD5500);

  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const background = Color(0xFFFFFFFF);
  static const onBackground = Color(0xFF1B1B24);
  static const surfaceVariant = Color(0xFFE4E1EE);

  /// Success color for reward-claim positive reinforcement (not in the raw
  /// token list but referenced throughout DESIGN.md's component section).
  static const success = Color(0xFF1DB876);

  /// Gold accent reserved strictly for high-value reward / "win" states.
  static const goldAccent = Color(0xFFFFD54A);

  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryContainer, secondary],
  );

  static const gradientGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD54A), Color(0xFFBD5500)],
  );
}
