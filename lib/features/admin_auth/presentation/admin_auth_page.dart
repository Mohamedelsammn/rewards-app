import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
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
        listener: (context, state) {
          if (state.status == AdminAuthStatus.success) {
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
                      const Icon(Icons.grid_view_rounded, color: AppColors.primary, size: 40),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        isSignUp ? l10n.adminAuthCreateAccount : l10n.adminAuthSignInTitle,
                        style: AppTypography.headlineMd,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        isSignUp ? l10n.adminAuthSignUpSubtitle : l10n.adminAuthSignInSubtitle,
                        style: AppTypography.bodyMd,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ModeToggle(mode: _mode, onChanged: _switchMode),
                      const SizedBox(height: AppSpacing.lg),
                      if (isSignUp) ...[
                        Text(l10n.adminAuthFullNameLabel, style: AppTypography.labelSm),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _fullNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline)),
                          validator: (v) => (v == null || v.trim().length < 2)
                              ? l10n.adminAuthFullNameError
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Text(l10n.adminAuthEmailLabel, style: AppTypography.labelSm),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined)),
                        validator: (v) =>
                            (v == null || !v.contains('@')) ? l10n.adminAuthEmailError : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(l10n.adminAuthPasswordLabel, style: AppTypography.labelSm),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return l10n.adminAuthPasswordEmptyError;
                          if (isSignUp && v.length < 8) return l10n.adminAuthPasswordLengthError;
                          return null;
                        },
                      ),
                      if (isSignUp) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(l10n.adminAuthConfirmPasswordLabel, style: AppTypography.labelSm),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirmPassword = !_obscureConfirmPassword,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v != _passwordController.text)
                              return l10n.adminAuthPasswordsNoMatch;
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(l10n.adminAuthAccessCodeLabel, style: AppTypography.labelSm),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _accessCodeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.vpn_key_outlined),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.adminAuthAccessCodeError
                              : null,
                        ),
                      ],
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
