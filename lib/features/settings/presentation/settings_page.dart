import 'dart:async';

import 'package:flutter/material.dart';
import '../../../services/ads/ad_service.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_visuals.dart';
import '../../../core/utils/phone_util.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/notification_service.dart';
import '../../../services/secure_storage_service.dart';
import '../../../shared/widgets/language_picker.dart';
import '../../../shared/widgets/primary_gradient_button.dart';
import '../../../shared/widgets/settings_section.dart';
import '../../legal/presentation/privacy_policy_page.dart';
import '../../role_selection/presentation/role_selection_page.dart';
import 'edit_profile_page.dart';

/// Language, profile, About, Privacy Policy, Terms & Conditions, Sign Out
/// (tasks.md T12-01). Grouped into premium, visually separated sections
/// rather than a raw ListTile stack.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _fullName;
  String? _phone;
  String? _countryCode;
  StreamSubscription<void>? _identitySub;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    // SettingsPage lives inside UserHomeShell's IndexedStack for the whole
    // shell's lifetime, so initState only ever runs once -- without this,
    // a registration completed elsewhere (Giveaway Details' participation
    // flow, not this screen) would never be reflected here until the next
    // fresh mount (app restart / role switch). See Edit Profile's own
    // pop-result callback below for the other write path into this same
    // cached identity.
    _identitySub = getIt<SecureStorageService>().identityChanged.listen((_) => _loadProfile());
  }

  @override
  void dispose() {
    _identitySub?.cancel();
    super.dispose();
  }

  /// Reads straight from the same locally cached identity Splash/Role
  /// Selection already rely on (see SecureStorageService's doc comment) --
  /// no new user record, no network call, no duplicating what
  /// register-or-link-user already persisted server-side.
  Future<void> _loadProfile() async {
    final storage = getIt<SecureStorageService>();
    final fullName = await storage.cachedFullName;
    final phone = await storage.cachedPhone;
    final countryCode = await storage.cachedCountryCode;
    if (!mounted) return;
    setState(() {
      _fullName = fullName;
      _phone = phone;
      _countryCode = countryCode;
    });
  }

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
    final ads = getIt.isRegistered<AdService>() ? getIt<AdService>() : null;
    final currentLanguage = Localizations.localeOf(context).languageCode == 'ar'
        ? 'العربية'
        : 'English';

    return SafeArea(
      bottom: false,
      // The Material ancestor ListTile needs is supplied once by
      // UserHomeShell (see its doc comment), not per-page.
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPadding,
            AppSpacing.md,
            AppSpacing.containerPadding,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.settingsTitle, style: AppTypography.headlineMd),
              const SizedBox(height: AppSpacing.lg),
              _ProfileHeader(fullName: _fullName, phone: _phone, countryCode: _countryCode),
              const SizedBox(height: AppSpacing.lg),
              if (_fullName != null && _fullName!.trim().isNotEmpty) ...[
                SettingsSection(
                  title: l10n.settingsSectionAccount,
                  children: [
                    SettingsRow(
                      icon: AppIcons.edit,
                      label: l10n.settingsEditProfile,
                      onTap: () async {
                        final updated = await Navigator.of(
                          context,
                        ).push<bool>(MaterialPageRoute(builder: (_) => const EditProfilePage()));
                        if (updated == true) _loadProfile();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              ListenableBuilder(
                listenable: ads ?? const AlwaysStoppedAnimation(false),
                builder: (context, _) => SettingsSection(
                  title: l10n.settingsSectionGeneral,
                  children: [
                    if (ads?.privacyRequired ?? false)
                      SettingsRow(
                        icon: AppIcons.privacy,
                        label: l10n.adsPrivacyChoices,
                        onTap: () => ads!.privacyOptions(),
                      ),
                    SettingsRow(
                      icon: AppIcons.language,
                      label: l10n.settingsLanguage,
                      trailing: currentLanguage,
                      onTap: () => showLanguagePicker(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SettingsSection(
                title: l10n.settingsSectionInformation,
                children: [
                  SettingsRow(
                    icon: AppIcons.info,
                    label: l10n.settingsAbout,
                    onTap: () => _showAbout(context),
                  ),
                  SettingsRow(
                    icon: AppIcons.privacy,
                    label: l10n.settingsPrivacyPolicy,
                    onTap: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyPage())),
                  ),
                  SettingsRow(
                    icon: AppIcons.document,
                    label: l10n.settingsTermsConditions,
                    onTap: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const TermsConditionsPage())),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              // Non-guests already saw the "Account" heading above the Edit
              // Profile card; repeating it here would read as a duplicate
              // section header, so it's only shown standalone for guests.
              if (_fullName == null || _fullName!.trim().isEmpty)
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
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.fullName, required this.phone, this.countryCode});

  final String? fullName;
  final String? phone;
  final String? countryCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isGuest = fullName == null || fullName!.trim().isEmpty;
    Country? country;
    for (final c in kCountries) {
      if (c.iso2 == countryCode) {
        country = c;
        break;
      }
    }
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final displayPhone = _formatProfilePhone(phone, country);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppVisuals.cardRadius),
        boxShadow: AppVisuals.cardShadow,
      ),
      child: Row(
        children: [
          const ProfileAvatar(radius: 27),
          const SizedBox(width: 18),
          // The identity read is async (secure storage), so the very first
          // frame always shows Guest; a subtle cross-fade -- rather than an
          // abrupt jump -- into the resolved name/phone once that read
          // completes reads as intentional instead of a layout glitch.
          Expanded(
            child: AnimatedSwitcher(
              duration: AppVisuals.fast,
              child: Column(
                key: ValueKey(isGuest ? 'guest' : fullName),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGuest ? l10n.userHomeGuest : fullName!,
                    style: AppTypography.headlineMd.copyWith(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isGuest) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.settingsGuestSubtitle,
                      style: AppTypography.bodyMd.copyWith(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.start,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else if (displayPhone != null) ...[
                    const SizedBox(height: 3),
                    Directionality(
                      key: const ValueKey('settings-profile-phone-direction'),
                      textDirection: TextDirection.ltr,
                      child: Text(
                        displayPhone,
                        key: const ValueKey('settings-profile-phone'),
                        style: AppTypography.bodyMd.copyWith(
                          fontSize: 14,
                          height: 1.35,
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: isRtl ? TextAlign.right : TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (!isGuest && country != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(country.flagEmoji, style: AppTypography.labelSm),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            country.name,
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats the cached E.164 identity for display only. Participation and
/// authentication continue using the untouched canonical value from storage.
String? _formatProfilePhone(String? rawPhone, Country? country) {
  final trimmed = rawPhone?.trim() ?? '';
  if (trimmed.isEmpty) return null;

  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  if (!trimmed.startsWith('+') || country == null || !digits.startsWith(country.dialCode)) {
    return trimmed;
  }

  final national = digits.substring(country.dialCode.length);
  final groups = switch (country.iso2) {
    'EG' when national.length == 10 => [
      national.substring(0, 2),
      national.substring(2, 6),
      national.substring(6),
    ],
    'US' || 'CA' when national.length == 10 => [
      national.substring(0, 3),
      national.substring(3, 6),
      national.substring(6),
    ],
    'GB' when national.length == 10 => [national.substring(0, 4), national.substring(4)],
    'AU' when national.length == 9 => [
      national.substring(0, 3),
      national.substring(3, 6),
      national.substring(6),
    ],
    'SA' || 'AE' when national.length == 9 => [
      national.substring(0, 2),
      national.substring(2, 5),
      national.substring(5),
    ],
    'IN' when national.length == 10 => [national.substring(0, 5), national.substring(5)],
    'DE' when national.length >= 10 => [
      national.substring(0, 3),
      national.substring(3, 6),
      national.substring(6),
    ],
    'FR' when national.length == 9 => [
      national.substring(0, 1),
      national.substring(1, 3),
      national.substring(3, 5),
      national.substring(5, 7),
      national.substring(7),
    ],
    _ => [national],
  };
  return '+${country.dialCode} ${groups.join(' ')}';
}
