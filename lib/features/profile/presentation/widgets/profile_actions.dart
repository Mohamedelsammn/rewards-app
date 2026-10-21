import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/bloc/session_cubit.dart';
import '../../domain/profile_repository.dart';

/// Language picker. Signed-in users also get `PATCH /me { language }` so
/// emails and pushes follow the app language.
Future<void> showLanguageSheet(BuildContext context) async {
  final controller = sl<LocaleController>();
  final session = context.read<SessionCubit>();
  await showModalBottomSheet<void>(
    context: context,
    // Above the shell's bottom navigation bar.
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: const BoxDecoration(
          color: AppColors.sheet,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Color(0x208073bd), blurRadius: 24, offset: Offset(0, -5))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xffd9d3ed),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              sheetContext.l10n.languageTitle,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            for (final option in const [
              (code: 'en', label: 'English'),
              (code: 'ar', label: 'العربية'),
            ]) ...[
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: ListTile(
                  key: ValueKey('language-${option.code}'),
                  minTileHeight: 58,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  tileColor: controller.value.languageCode == option.code
                      ? const Color(0xffede8ff)
                      : Colors.white,
                  title: Text(
                    option.label,
                    style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
                  ),
                  trailing: controller.value.languageCode == option.code
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.violet)
                      : const Icon(Icons.circle_outlined, color: AppColors.muted),
                  onTap: () async {
                    await controller.setLocale(Locale(option.code));
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                    if (session.state.isAuthenticated &&
                        session.state.user?.language != option.code) {
                      try {
                        session.userUpdated(
                          await sl<ProfileRepository>().updateProfile(language: option.code),
                        );
                      } catch (_) {
                        // The local choice still applies; the server copy syncs next time.
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    ),
  );
}

class SignOutButton extends StatefulWidget {
  const SignOutButton({super.key});

  @override
  State<SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<SignOutButton> {
  bool _busy = false;

  Future<void> _confirm() async {
    if (_busy) return;
    final l10n = context.l10n;
    final confirmed = await showAppConfirmDialog(
      context,
      icon: AppIcons.logout,
      title: l10n.signOutTitle,
      message: l10n.signOutMessage,
      confirmLabel: l10n.profileSignOut,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      // The router leaves the shell once the session is unauthenticated.
      await context.read<SessionCubit>().signOut();
    } catch (_) {
      if (mounted) showAppSnackBar(context, l10n.errUnknown);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => InkWell(
    key: const ValueKey('profile-sign-out'),
    onTap: _busy ? null : _confirm,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xffffedf0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffffd7de)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xffd83a53)),
            )
          else
            const Icon(AppIcons.logout, color: Color(0xffd83a53), size: 21),
          const SizedBox(width: 12),
          Text(
            context.l10n.profileSignOut,
            style: const TextStyle(
              color: Color(0xffc82e48),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),
  );
}
