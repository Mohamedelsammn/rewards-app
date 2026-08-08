import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography scale from DESIGN.md: Plus Jakarta Sans for headlines,
/// Manrope for body/functional text. Both are bundled locally as variable
/// fonts under assets/fonts/ (see pubspec.yaml) -- no google_fonts runtime
/// dependency, no network fetch, works fully offline.
class AppTypography {
  const AppTypography._();

  static TextStyle get display => const TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 40,
    fontWeight: FontWeight.w800,
    height: 48 / 40,
    letterSpacing: -0.02 * 40,
    color: AppColors.onSurface,
  );

  static TextStyle get headlineLg => const TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    letterSpacing: -0.01 * 32,
    color: AppColors.onSurface,
  );

  static TextStyle get headlineLgMobile => const TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 34 / 28,
    letterSpacing: -0.01 * 28,
    color: AppColors.onSurface,
  );

  static TextStyle get headlineMd => const TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    color: AppColors.onSurface,
  );

  static TextStyle get bodyLg => const TextStyle(
    fontFamily: 'Manrope',
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 28 / 18,
    color: AppColors.onSurface,
  );

  static TextStyle get bodyMd => const TextStyle(
    fontFamily: 'Manrope',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle get labelSm => const TextStyle(
    fontFamily: 'Manrope',
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 16 / 13,
    letterSpacing: 0.05 * 13,
    color: AppColors.onSurfaceVariant,
  );
}
