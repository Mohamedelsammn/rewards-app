import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/localization/error_messages.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/submit_state.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/auth_backdrop.dart';
import '../../../../core/widgets/auth_top.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../bloc/auth_flow_cubits.dart';
import '../onboarding_draft.dart';
import '../widgets/password_fields.dart';

/// Step 3 (create password) or the forgot-password reset.
class PasswordPage extends StatelessWidget {
  const PasswordPage({required this.draft, super.key});

  final OnboardingDraft draft;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ResetPasswordCubit(sl()),
    child: _PasswordView(draft: draft),
  );
}

class _PasswordView extends StatefulWidget {
  const _PasswordView({required this.draft});

  final OnboardingDraft draft;

  @override
  State<_PasswordView> createState() => _PasswordViewState();
}

class _PasswordViewState extends State<_PasswordView> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = context.l10n;
    if (!Validators.passwordAcceptable(_password.text)) {
      setState(() => _error = l10n.passwordTooWeak);
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = l10n.passwordMismatch);
      return;
    }
    final draft = widget.draft;
    if (draft.isReset) {
      context.read<ResetPasswordCubit>().reset(
        email: draft.email,
        verificationToken: draft.verificationToken!,
        newPassword: _password.text,
      );
    } else {
      context.push(Routes.registerCharacter, extra: draft.copyWith(password: _password.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reset = widget.draft.isReset;
    return BlocConsumer<ResetPasswordCubit, SubmitState<void>>(
      listener: (context, state) {
        if (state.status == SubmitStatus.success) {
          showAppSnackBar(context, l10n.passwordResetDone);
          context.go(Routes.login, extra: widget.draft.email);
        } else if (state.status == SubmitStatus.failure) {
          if (requiresRestart(state.error)) {
            showErrorSnackBar(context, state.error!);
            context.go(Routes.login, extra: widget.draft.email);
          } else {
            setState(() => _error = errorMessage(context, state.error!));
          }
        }
      },
      builder: (context, state) => AuthBackdrop(
        image: AppAssets.passwordBackground,
        artTopFraction: 0,
        child: AutofillGroup(
          child: Column(
            children: [
              AuthTop(step: reset ? -1 : 2),
              const SizedBox(height: 38),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: reset ? l10n.passwordResetTitleStart : l10n.passwordTitleStart),
                    TextSpan(
                      text: reset ? l10n.passwordResetTitleAccent : l10n.passwordTitleAccent,
                      style: const TextStyle(color: AppColors.violet),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              Text(
                l10n.passwordSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 17),
              ),
              const SizedBox(height: 28),
              PasswordField(
                controller: _password,
                label: l10n.passwordLabel,
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _confirm,
                label: l10n.passwordConfirmLabel,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() => _error = null),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!, style: const TextStyle(color: AppColors.error)),
                ),
              const SizedBox(height: 20),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _password,
                builder: (_, value, _) => PasswordRules(password: value.text),
              ),
              const SizedBox(height: 250),
              GradientButton(
                reset ? l10n.passwordSave : l10n.commonContinue,
                busy: state.busy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
