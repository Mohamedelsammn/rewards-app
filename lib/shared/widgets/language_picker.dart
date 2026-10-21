import 'package:flutter/material.dart';
import '../../core/theme/app_icons.dart';

import '../../core/di/injection.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// The single language-picker bottom sheet used everywhere the app lets the
/// user switch language (User Settings, Admin Profile). Reuses
/// [LocaleController] -- the app's one localization mechanism -- so there is
/// exactly one picker implementation and one persisted preference, never a
/// second parallel localization system for Admin.
Future<void> showLanguagePicker(BuildContext context) async {
  final controller = getIt<LocaleController>();
  final chosen = await showModalBottomSheet<Locale>(
    context: context,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final locale in kSupportedLocales)
            ListTile(
              title: Text(
                locale.languageCode == 'ar' ? 'العربية' : 'English',
                style: AppTypography.bodyLg,
              ),
              trailing: controller.value == locale
                  ? const Icon(AppIcons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(locale),
            ),
        ],
      ),
    ),
  );

  if (chosen != null) {
    await controller.setLocale(chosen);
  }
}
