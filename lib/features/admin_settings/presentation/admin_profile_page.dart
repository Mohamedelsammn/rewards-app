import 'package:flutter/material.dart';
import '../../../core/theme/app_icons.dart';
import '../../../shared/repositories/category_repository.dart';
import '../../categories/presentation/category_management_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/secure_storage_service.dart';
import '../../../shared/repositories/auth_repository.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/language_picker.dart';
import '../../../shared/widgets/primary_gradient_button.dart';
import '../../../shared/widgets/settings_section.dart';
import '../../role_selection/presentation/role_selection_page.dart';

/// Same visual language as User Settings (large profile header, grouped
/// section cards, a large primary-styled Sign Out button) via the shared
/// [SettingsSection]/[SettingsRow]/[ProfileAvatar] widgets -- one grouped-
/// settings look for the whole app, not a separate Admin-only style.
class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsSignOutConfirmTitle),
        content: Text(l10n.adminProfileSignOutConfirmBody),
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

    // Admin authentication/security model is untouched here -- this only
    // adds a confirmation step in front of the same AuthRepository.signOut()
    // call that was already here. Clearing the persisted "last active role"
    // is what makes an explicit sign-out correctly show Role Selection on
    // the next launch instead of trying (and failing, since the session is
    // now gone) to restore straight back into AdminShell -- see
    // docs/fixes/state-sync-and-session-restoration.md. This has zero
    // interaction with the User side's anonymous session/identity/
    // participation history, which live under entirely separate storage
    // keys untouched by this call.
    await getIt<AuthRepository>().signOut();
    await getIt<SecureStorageService>().clearLastRole();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = getIt<SupabaseClient>().auth.currentUser;
    final l10n = AppLocalizations.of(context);
    final currentLanguage = Localizations.localeOf(context).languageCode == 'ar'
        ? 'العربية'
        : 'English';
    final fullName =
        (user?.userMetadata?['full_name'] as String?) ?? l10n.adminProfileAdministrator;
    final email = user?.email ?? '';

    return SafeArea(
      bottom: false,
      // The Material ancestor ListTile needs is supplied once by
      // AdminShell (see its doc comment), not per-page.
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.containerPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.adminProfileTitle, style: AppTypography.headlineMd),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const ProfileAvatar(icon: AppIcons.categories),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      fullName,
                      style: AppTypography.headlineMd.copyWith(fontSize: 20),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: AppTypography.bodyMd,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SettingsSection(
                title: l10n.settingsSectionGeneral,
                children: [
                  if (getIt.isRegistered<CategoryRepository>())
                    FutureBuilder<bool>(
                      future: getIt<CategoryRepository>().canManage(),
                      builder: (context, snapshot) => snapshot.data == true
                          ? SettingsRow(
                              icon: AppIcons.categories,
                              label: l10n.categoryManagement,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const CategoryManagementPage()),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  SettingsRow(
                    icon: AppIcons.language,
                    label: l10n.settingsLanguage,
                    trailing: currentLanguage,
                    onTap: () => showLanguagePicker(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.xs,
                  bottom: AppSpacing.sm,
                ),
                child: Text(l10n.settingsSectionAccount, style: AppTypography.labelSm),
              ),
              PrimaryGradientButton(
                label: l10n.settingsSignOut,
                icon: AppIcons.logout,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.error, AppColors.error.withValues(alpha: 0.8)],
                ),
                onPressed: () => _signOut(context),
              ),
              SizedBox(height: AppBottomNav.footprint(context) + AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
