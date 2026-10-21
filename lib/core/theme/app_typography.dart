import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Text styles of the redesign. Headlines and body both use the bundled
/// Plus Jakarta Sans variable font.
class AppTypography {
  const AppTypography._();

  static const fontFamily = 'Plus Jakarta Sans';

  static const textTheme = TextTheme(
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.ink),
    headlineMedium: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: AppColors.ink),
    titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.ink),
    bodyLarge: TextStyle(fontSize: 16, color: AppColors.ink),
  );

  static const sectionTitle = TextStyle(
    color: AppColors.ink,
    fontSize: 22,
    fontWeight: FontWeight.w800,
  );
  static const subtitle = TextStyle(color: AppColors.muted, fontSize: 17);
  static const body = TextStyle(fontSize: 16, height: 1.5, color: AppColors.ink);
  static const cardTitle = TextStyle(
    color: AppColors.ink,
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );
  static const caption = TextStyle(color: AppColors.muted, fontSize: 13);
  static const price = TextStyle(
    color: AppColors.violet,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static const buttonLabel = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
  static const sheetTitle = TextStyle(
    color: AppColors.ink,
    fontSize: 23,
    fontWeight: FontWeight.w800,
  );
}
