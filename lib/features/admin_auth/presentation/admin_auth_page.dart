import 'package:flutter/material.dart';
import '../../../core/theme/app_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/secure_storage_service.dart';
import '../../../shared/widgets/primary_gradient_button.dart';
import '../../admin_dashboard/presentation/admin_shell.dart';
import 'bloc/admin_auth_cubit.dart';
import 'bloc/admin_auth_state.dart';

enum _AdminAuthMode { signIn, signUp }

/// Admin Role → Admin Authentication (Sign In / Sign Up) → Admin Dashboard
/// (per the required flow). Not present in the provided mockups -- required
/// per implementation-plan.md §1.4 #7: admin actions are privileged and
/// cannot rely on anonymous auth.
///
/// Sign-up is self-service (admins aren't predefined) but gated server-side
/// by a shared access code (see `admin-sign-up` Edge Function /
/// `fn_verify_admin_signup_code`) -- picking "Admin" on Role Selection alone
/// never grants admin privileges.
class AdminAuthPage extends StatelessWidget {
  const AdminAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => AdminAuthCubit(getIt()), child: const _AdminAuthView());
  }
}

class _AdminAuthView extends StatefulWidget {
  const _AdminAuthView();

  @override
  State<_AdminAuthView> createState() => _AdminAuthViewState();
}

class _AdminAuthViewState extends State<_AdminAuthView> {
  _AdminAuthMode _mode = _AdminAuthMode.signIn;

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _accessCodeController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  void _switchMode(_AdminAuthMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    context.read<AdminAuthCubit>().reset();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<AdminAuthCubit>();
    if (_mode == _AdminAuthMode.signIn) {
      cubit.signIn(email: _emailController.text.trim(), password: _passwordController.text);
    } else {
      cubit.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        accessCode: _accessCodeController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSignUp = _mode == _AdminAuthMode.signUp;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l10n.adminAuthTitle)),
      body: BlocConsumer<AdminAuthCubit, AdminAuthState>(
        listener: (context, state) async {
          if (state.status == AdminAuthStatus.success) {
            // Persists which role was last active on this device (mirrors
            // RoleSelectionPage's `saveLastRole('user')`) so SplashCubit can
            // restore straight into AdminShell on the next app
            // restart/reload instead of bouncing back to Role Selection --
            // see docs/fixes/state-sync-and-session-restoration.md.
            await getIt<SecureStorageService>().saveLastRole('admin');
            if (!context.mounted) return;
            Navigator.of(
              context,
            ).pushReplacement(MaterialPageRoute(builder: (_) => const AdminShell()));
          }
        },
        builder: (context, state) {
          final isSubmitting = state.status == AdminAuthStatus.submitting;
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.containerPadding),
            child: Center(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(AppIcons.categories, color: AppColors.primary, size: 40),
                      const SizedBox(height: AppSpacing.md),
                      _AnimatedAuthSwitch(
                        // Keying by mode cross-fades+slides the title/subtitle
                        // pair together as one unit rather than each text
                        // jumping independently.
                        switchKey: ValueKey('title-$_mode'),
                        child: Column(
                          children: [
                            Text(
                              isSignUp ? l10n.adminAuthCreateAccount : l10n.adminAuthSignInTitle,
                              style: AppTypography.headlineMd,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              isSignUp
                                  ? l10n.adminAuthSignUpSubtitle
                                  : l10n.adminAuthSignInSubtitle,
                              style: AppTypography.bodyMd,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ModeToggle(mode: _mode, onChanged: _switchMode),
                      const SizedBox(height: AppSpacing.lg),
                      // Full Name only exists for Sign Up. Animated in/out
                      // rather than abruptly inserted/removed -- the shared
                      // Email/Password fields below stay permanently mounted
                      // (never rebuilt), so their typed values and focus
                      // survive a mode switch untouched.
                      _AnimatedFormSection(
                        visible: isSignUp,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(l10n.adminAuthFullNameLabel, style: AppTypography.labelSm),
                            const SizedBox(height: AppSpacing.xs),
                            TextFormField(
                              controller: _fullNameController,
                              textCapitalization: TextCapitalization.words,
                              autofillHints: isSignUp ? const [AutofillHints.name] : null,
                              onTapOutside: (_) => FocusScope.of(context).unfocus(),
                              decoration: InputDecoration(
                                hintText: l10n.adminAuthFullNameHint,
                                prefixIcon: const Icon(AppIcons.profile),
                              ),
                              validator: (v) => isSignUp && (v == null || v.trim().length < 2)
                                  ? l10n.adminAuthFullNameError
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ),
                      ),
                      Text(l10n.adminAuthEmailLabel, style: AppTypography.labelSm),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          hintText: l10n.adminAuthEmailHint,
                          prefixIcon: const Icon(AppIcons.mail),
                        ),
                        validator: (v) =>
                            (v == null || !v.contains('@')) ? l10n.adminAuthEmailError : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(l10n.adminAuthPasswordLabel, style: AppTypography.labelSm),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: [
                          isSignUp ? AutofillHints.newPassword : AutofillHints.password,
                        ],
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          hintText: l10n.adminAuthPasswordHint,
                          helperText: isSignUp ? l10n.adminAuthPasswordRequirementHelper : null,
                          helperMaxLines: 2,
                          prefixIcon: const Icon(AppIcons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? AppIcons.eye : AppIcons.eyeOff),
                            tooltip: _obscurePassword
                                ? l10n.commonShowPassword
                                : l10n.commonHidePassword,
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return l10n.adminAuthPasswordEmptyError;
                          if (isSignUp && v.length < 8) return l10n.adminAuthPasswordLengthError;
                          return null;
                        },
                      ),
                      // Confirm Password + Access Code only exist for Sign Up.
                      _AnimatedFormSection(
                        visible: isSignUp,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: AppSpacing.md),
                            Text(l10n.adminAuthConfirmPasswordLabel, style: AppTypography.labelSm),
                            const SizedBox(height: AppSpacing.xs),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              autofillHints: isSignUp ? const [AutofillHints.newPassword] : null,
                              onTapOutside: (_) => FocusScope.of(context).unfocus(),
                              decoration: InputDecoration(
                                hintText: l10n.adminAuthPasswordHint,
                                prefixIcon: const Icon(AppIcons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? AppIcons.eye : AppIcons.eyeOff,
                                  ),
                                  tooltip: _obscureConfirmPassword
                                      ? l10n.commonShowPassword
                                      : l10n.commonHidePassword,
                                  onPressed: () => setState(
                                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (!isSignUp) return null;
                                if (v != _passwordController.text) {
                                  return l10n.adminAuthPasswordsNoMatch;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(l10n.adminAuthAccessCodeLabel, style: AppTypography.labelSm),
                            const SizedBox(height: AppSpacing.xs),
                            TextFormField(
                              controller: _accessCodeController,
                              textCapitalization: TextCapitalization.characters,
                              onTapOutside: (_) => FocusScope.of(context).unfocus(),
                              decoration: InputDecoration(
                                hintText: l10n.adminAuthAccessCodeHint,
                                prefixIcon: const Icon(AppIcons.keyIcon),
                              ),
                              validator: (v) => isSignUp && (v == null || v.trim().isEmpty)
                                  ? l10n.adminAuthAccessCodeError
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const _AdminContactSection(),
                          ],
                        ),
                      ),
                      if (state.status == AdminAuthStatus.error) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          state.failure?.localize(l10n) ?? l10n.commonSomethingWrong,
                          style: AppTypography.bodyMd.copyWith(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      PrimaryGradientButton(
                        label: isSignUp
                            ? l10n.adminAuthCreateAccountButton
                            : l10n.adminAuthSignInButton,
                        isLoading: isSubmitting,
                        onPressed: isSubmitting ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final _AdminAuthMode mode;
  final ValueChanged<_AdminAuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: l10n.adminAuthSignIn,
              selected: mode == _AdminAuthMode.signIn,
              onTap: () => onChanged(_AdminAuthMode.signIn),
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: l10n.adminAuthSignUp,
              selected: mode == _AdminAuthMode.signUp,
              onTap: () => onChanged(_AdminAuthMode.signUp),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 8)]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMd.copyWith(
            color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

const _authTransitionDuration = Duration(milliseconds: 320);
const _authTransitionCurve = Curves.easeOutCubic;

/// Cross-fades + slightly slides between two versions of the same content
/// (e.g. the title/subtitle pair), keyed by [switchKey] so Sign In <-> Sign
/// Up feels like one polished, continuous transition rather than an abrupt
/// text swap.
class _AnimatedAuthSwitch extends StatelessWidget {
  const _AnimatedAuthSwitch({required this.switchKey, required this.child});

  final Key switchKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: _authTransitionDuration,
      switchInCurve: _authTransitionCurve,
      switchOutCurve: _authTransitionCurve,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.06),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: switchKey, child: child),
    );
  }
}

/// Smoothly reveals/hides a block of Sign-Up-only fields: an [AnimatedSize]
/// (height) wrapping an [AnimatedSwitcher] (fade + slight slide) between the
/// section and an empty placeholder. No layout jump, no flicker -- and the
/// shared Email/Password fields around this section stay permanently
/// mounted, so switching modes never loses what the admin already typed
/// there or steals keyboard focus away mid-edit.
class _AnimatedFormSection extends StatelessWidget {
  const _AnimatedFormSection({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: _authTransitionDuration,
      curve: _authTransitionCurve,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: _authTransitionDuration,
        switchInCurve: _authTransitionCurve,
        switchOutCurve: _authTransitionCurve,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.04),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: visible
            ? KeyedSubtree(key: const ValueKey('visible'), child: child)
            : const SizedBox(width: double.infinity, key: ValueKey('hidden')),
      ),
    );
  }
}

/// Replaces the old phone-call requirement: someone without an Admin Access
/// Code can reach the administrator over a normal WhatsApp deep link
/// (`wa.me`), never a paid/Business API. [AppConfig.adminContactPhone] is
/// the single source of truth for the number -- both the label shown here
/// and the `wa.me` URL read the same constant, so it's never duplicated.
class _AdminContactSection extends StatelessWidget {
  const _AdminContactSection();

  Future<void> _openWhatsApp(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final phoneDigits = AppConfig.adminContactPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse(
      'https://wa.me/$phoneDigits'
      '?text=${Uri.encodeComponent(l10n.adminAuthWhatsAppPrefilledMessage)}',
    );

    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminAuthWhatsAppOpenFailed), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.adminAuthNoAccessCodeQuestion,
            style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.adminAuthContactWhatsAppSubtitle,
            style: AppTypography.labelSm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Material(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.full),
              onTap: () => _openWhatsApp(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: AppSpacing.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(AppIcons.message, color: AppColors.success, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        AppConfig.adminContactPhone,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
