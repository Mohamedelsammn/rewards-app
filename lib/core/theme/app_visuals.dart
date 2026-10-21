import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Shared lightweight surfaces and motion; no backdrop filters for content.
class AppVisuals {
  const AppVisuals._();
  static const fast = Duration(milliseconds: 180);
  static const icon = 20.0;
  static const smallIcon = 16.0;
  static const touchTarget = 48.0;
  static const cardRadius = 20.0;
  static const fieldRadius = 20.0;
  static const chipRadius = 22.0;
  static const cardShadow = [
    BoxShadow(color: Color(0x0A4042E1), blurRadius: 12, offset: Offset(0, 3)),
  ];
  static const divider = Color(0xFFF0EDF6);
  static const upcoming = Color(0xFF246BEB);
  static const endingSoon = Color(0xFFE97928);
  static const ended = Color(0xFF757986);
  static const active = Color(0xFF009E70);
  static const chipSurface = AppColors.surfaceContainer;
}
