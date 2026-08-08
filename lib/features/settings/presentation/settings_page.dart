import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/notification_service.dart';
import '../../../services/secure_storage_service.dart';
import '../../legal/presentation/privacy_policy_page.dart';
import '../../role_selection/presentation/role_selection_page.dart';

/// Intentionally minimal per the brief -- Language, About, Privacy Policy,
/// Terms & Conditions, Sign Out (tasks.md T12-01).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsSignOutConfirmTitle),
        content: Text(l10n.settingsSignOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.settingsSignOut, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Deliberately does NOT sign out of Supabase Auth: the anonymous session
    // is the RLS identity chain (auth.uid() -> user_devices -> users) that
    // this device's participation history depends on. Destroying it would
    // orphan the cached identity until the user re-registers. "Sign Out"
    // here means "leave the User section," not "log out of an account" --
    // there is no traditional user login to log out of by design. Only the
    // navigation flag is cleared; identity cache and Hive cache are untouched.
    //
    // The device's FCM token IS invalidated server-side though: a signed-out
    // device shouldn't keep receiving winner pushes for an identity it no
    // longer actively represents in the UI.
    await getIt<NotificationService>().invalidateToken();
    await getIt<SecureStorageService>().clearLastRole();

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
      (route) => false,
    );
  }

  Future<void> _pickLanguage(BuildContext context) async {
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
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
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

  void _showAbout(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsAbout),
        content: Text(l10n.settingsAboutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonDismiss),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLanguage = Localizations.localeOf(context).languageCode == 'ar'
        ? 'العربية'
        : 'English';

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPadding,
              AppSpacing.md,
              AppSpacing.containerPadding,
              AppSpacing.sm,
            ),
            child: Text(l10n.settingsTitle, style: AppTypography.headlineMd),
          ),
          _SettingsTile(
            icon: Icons.language_rounded,
            label: l10n.settingsLanguage,
            trailing: currentLanguage,
            onTap: () => _pickLanguage(context),
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: l10n.settingsAbout,
            onTap: () => _showAbout(context),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            label: l10n.settingsPrivacyPolicy,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyPage())),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            label: l10n.settingsTermsConditions,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const TermsConditionsPage())),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.containerPadding,
              vertical: AppSpacing.sm,
            ),
            child: Divider(height: 1, color: AppColors.outlineVariant),
          ),
          _SettingsTile(
            icon: Icons.logout_rounded,
            label: l10n.settingsSignOut,
            iconColor: AppColors.error,
            labelColor: AppColors.error,
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.iconColor,
    this.labelColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final Color? iconColor;
  final Color? labelColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary),
      title: Text(label, style: AppTypography.bodyLg.copyWith(color: labelColor)),
      trailing: trailing != null
          ? Text(trailing!, style: AppTypography.bodyMd)
          : (onTap != null
                ? null
                : const Icon(Icons.chevron_right_rounded, color: AppColors.outline)),
      onTap: onTap ?? () {},
    );
  }
}
