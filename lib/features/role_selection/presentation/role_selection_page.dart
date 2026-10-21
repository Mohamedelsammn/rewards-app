import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/secure_storage_service.dart';
import '../../../services/user_identity_service.dart';
import '../../admin_auth/presentation/admin_auth_page.dart';
import '../../user_home/presentation/user_home_shell.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  bool _continuingAsUser = false;

  /// Verifies the device's identity is genuinely still valid *before*
  /// entering the User flow -- not just a bare session check. Sign Out
  /// deliberately keeps the local identity cache and the Supabase session
  /// alive so returning here restores exactly what was there before; this
  /// is what confirms that promise actually holds (and safely clears a
  /// stale cache instead of silently failing later) rather than trusting a
  /// single one-shot attempt made back at Splash. See
  /// [UserIdentityService] for the full rationale.
  Future<void> _continueAsUser() async {
    setState(() => _continuingAsUser = true);
    await getIt<UserIdentityService>().restoreAndVerify();
    await getIt<SecureStorageService>().saveLastRole('user');
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const UserHomeShell()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.containerPadding),
          child: Column(
            children: [
              const Spacer(),
              Text(
                l10n.roleSelectionWelcome,
                style: AppTypography.headlineLg,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.roleSelectionChooseHow,
                style: AppTypography.bodyMd,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              _RoleCard(
                icon: Icons.card_giftcard_rounded,
                title: l10n.roleSelectionContinueAsUser,
                subtitle: l10n.roleSelectionContinueAsUserSubtitle,
                loading: _continuingAsUser,
                onTap: _continuingAsUser ? null : _continueAsUser,
              ),
              const SizedBox(height: AppSpacing.md),
              _RoleCard(
                icon: Icons.grid_view_rounded,
                title: l10n.roleSelectionContinueAsAdmin,
                subtitle: l10n.roleSelectionContinueAsAdminSubtitle,
                onTap: _continuingAsUser
                    ? null
                    : () {
                        Navigator.of(
                          context,
                        ).push(MaterialPageRoute(builder: (_) => const AdminAuthPage()));
                      },
              ),
              const Spacer(),
              Text(
                l10n.roleSelectionSwitchAnytime,
                style: AppTypography.labelSm,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppSpacing.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.lg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.primary),
                  ),
                  if (loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: AppTypography.headlineMd),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle, style: AppTypography.bodyMd),
            ],
          ),
        ),
      ),
    );
  }
}
