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
import '../../domain/entities/auth_entities.dart';
import '../bloc/auth_flow_cubits.dart';
import '../onboarding_draft.dart';

/// Registration step 1: email entry, then `POST /auth/otp/send`.
class EmailPage extends StatelessWidget {
  const EmailPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => SendCodeCubit(sl()), child: const _EmailView());
}

class _EmailView extends StatefulWidget {
  const _EmailView();

  @override
  State<_EmailView> createState() => _EmailViewState();
}

class _EmailViewState extends State<_EmailView> {
  final _controller = TextEditingController();
  String? _localError;
  String _sentTo = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!Validators.email(_controller.text)) {
      setState(() => _localError = context.l10n.authInvalidEmail);
      return;
    }
    _sentTo = Validators.normalizeEmail(_controller.text);
    context.read<SendCodeCubit>().send(
      email: _sentTo,
      purpose: OtpPurpose.register,
      language: context.languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<SendCodeCubit, SubmitState<OtpSendResult>>(
      listener: (context, state) {
        if (state.status == SubmitStatus.success) {
          context.push(
            Routes.registerOtp,
            extra: OnboardingDraft(
              email: _sentTo,
              purpose: OtpPurpose.register,
              resendAfter: state.result?.resendAfter ?? 60,
            ),
          );
        }
      },
      builder: (context, state) {
        final error =
            _localError ??
            (state.status == SubmitStatus.failure ? errorMessage(context, state.error!) : null);
        return AuthBackdrop(
          image: AppAssets.signinBackground,
          artOnTop: true,
          child: Column(
            children: [
              const AuthTop(step: 0),
              SizedBox(height: MediaQuery.sizeOf(context).height * .42),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: l10n.emailTitleStart),
                    TextSpan(
                      text: l10n.emailTitleAccent,
                      style: const TextStyle(color: AppColors.violet),
                    ),
                  ],
                ),
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.emailSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 17),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                onChanged: (_) {
                  if (_localError != null) setState(() => _localError = null);
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.mail_outline),
                  hintText: 'name@example.com',
                  errorText: error,
                  errorMaxLines: 3,
                ),
              ),
              const SizedBox(height: 28),
              GradientButton(l10n.emailSendCode, busy: state.busy, onPressed: _submit),
              TextButton(
                onPressed: () => context.push(Routes.login),
                child: Text(l10n.emailLoginInstead),
              ),
            ],
          ),
        );
      },
    );
  }
}
