import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// The Material theme taken from the redesign's `MaterialApp`.
class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.field),
      borderSide: const BorderSide(color: AppColors.fieldBorder),
    );
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.pale,
      fontFamily: AppTypography.fontFamily,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.violet, surface: AppColors.pale),
      textTheme: AppTypography.textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.pale,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: .88),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        border: border,
        enabledBorder: border,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
