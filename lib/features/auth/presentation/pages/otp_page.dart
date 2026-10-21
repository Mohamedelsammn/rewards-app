import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/localization/error_messages.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/auth_backdrop.dart';
import '../../../../core/widgets/auth_top.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/auth_entities.dart';
import '../bloc/otp_cubit.dart';
import '../onboarding_draft.dart';
import '../widgets/otp_code_field.dart';

/// Step 2 (registration) or the forgot-password code check.
class OtpPage extends StatelessWidget {
  const OtpPage({required this.draft, super.key});

  final OnboardingDraft draft;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => OtpCubit(
      sl(),
      email: draft.email,
      purpose: draft.purpose,
      language: context.languageCode,
      resendAfter: draft.resendAfter,
    ),
    child: _OtpView(draft: draft),
  );
}

class _OtpView extends StatefulWidget {
  const _OtpView({required this.draft});

  final OnboardingDraft draft;

  @override
  State<_OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<_OtpView> {
  final _controller = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _verify() {
    if (!Validators.otp(_controller.text)) {
      setState(() => _localError = context.l10n.otpEnterSix);
      return;
    }
    // Coming back from the password step: the proof is still unused, so
    // continue with it instead of re-verifying a consumed code.
    final verified = context.read<OtpCubit>().state.verification;
    if (verified != null) return _continue(verified);
    context.read<OtpCubit>().verify(_controller.text);
  }

  void _continue(OtpVerification verification) => context.push(
    widget.draft.isReset ? Routes.forgotPassword : Routes.registerPassword,
    extra: widget.draft.copyWith(verificationToken: verification.verificationToken),
  );

  String? _errorText(OtpState state) {
    if (_localError != null) return _localError;
    final error = state.error;
    if (error == null) return null;
    final message = errorMessage(context, error);
    final left = error is AppException ? error.details['attemptsLeft'] : null;
    return left is num ? '$message ${context.l10n.otpAttemptsLeft(left.toInt())}' : message;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<OtpCubit, OtpState>(
      listenWhen: (previous, current) =>
          previous.verification != current.verification || current.resent != previous.resent,
      listener: (context, state) {
        if (state.resent) {
          _controller.clear();
          showAppSnackBar(context, l10n.otpResent);
        }
        final verification = state.verification;
        if (verification != null) _continue(verification);
      },
      builder: (context, state) => AuthBackdrop(
        image: AppAssets.otpBackground,
        child: Column(
          children: [
            AuthTop(step: widget.draft.isReset ? -1 : 1),
            const SizedBox(height: 50),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: l10n.otpTitleStart),
                  TextSpan(
                    text: l10n.otpTitleAccent,
                    style: const TextStyle(color: AppColors.violet),
                  ),
                ],
              ),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.otpSentTo,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 17),
            ),
            Text(
              widget.draft.email,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 34),
            OtpCodeField(
              controller: _controller,
              enabled: !state.verifying,
              onChanged: (value) {
                if (_localError != null) setState(() => _localError = null);
                context.read<OtpCubit>().clearError();
                if (value.length == 6) _verify();
              },
            ),
            if (_errorText(state) case final text?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: state.secondsLeft == 0 && !state.resending
                  ? context.read<OtpCubit>().resend
                  : null,
              child: Text(
                state.secondsLeft == 0
                    ? l10n.otpResend
                    : l10n.otpResendIn(Formatters.countdown(state.secondsLeft)),
              ),
            ),
            Text(
              l10n.otpSpamHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            GradientButton(
              l10n.commonContinue,
              busy: state.verifying,
              onPressed: state.needsNewCode ? null : _verify,
            ),
            const SizedBox(height: 280),
          ],
        ),
      ),
    );
  }
}
