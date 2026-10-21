import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/constants/app_info.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/services/admob_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/headers.dart';

/// Security and preference entry points.
class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool _privacyOptions = false;

  @override
  void initState() {
    super.initState();
    // The UMP "privacy options" entry point is only shown where required.
    sl<AdMobService>().refreshPrivacyStatus().then((required) {
      if (mounted) setState(() => _privacyOptions = required);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final info = sl<AppInfo>();
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SecondaryHeader(title: l10n.settingsTitle, subtitle: l10n.settingsSubtitle),
            const SizedBox(height: 22),
            _SettingsRow(
              AppIcons.edit,
              l10n.editProfileTitle,
              () => context.push(Routes.editProfile),
            ),
            _SettingsRow(
              LucideIcons.keyRound,
              l10n.settingsChangePassword,
              () => context.push(Routes.changePassword),
            ),
            _SettingsRow(
              LucideIcons.smartphone,
              l10n.settingsSessions,
              () => context.push(Routes.sessions),
            ),
            _SettingsRow(
              AppIcons.bell,
              l10n.settingsNotifications,
              () => context.push(Routes.notificationSettings),
            ),
            if (_privacyOptions)
              _SettingsRow(
                LucideIcons.shieldCheck,
                l10n.settingsAdPrivacy,
                sl<AdMobService>().showPrivacyOptions,
              ),
            _SettingsRow(
              LucideIcons.trash2,
              l10n.settingsDeleteAccount,
              () => context.push(Routes.deleteAccount),
              destructive: true,
            ),
            const SizedBox(height: 18),
            Text(
              l10n.settingsVersion('${info.version} (${info.buildNumber})'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow(this.icon, this.label, this.onTap, {this.destructive = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : AppColors.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Icon(icon, color: color),
        title: Text(label, style: TextStyle(color: color)),
        trailing: const Icon(AppIcons.next, color: AppColors.muted),
        onTap: onTap,
      ),
    );
  }
}
