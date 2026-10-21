import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_entities.dart';
import '../bloc/auth_flow_cubits.dart';
import '../bloc/session_cubit.dart';
import '../onboarding_draft.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({this.initialEmail, super.key});

  final String? initialEmail;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => LoginCubit(sl())),
      BlocProvider(create: (_) => SendCodeCubit(sl())),
    ],
    child: _LoginView(initialEmail: initialEmail),
  );
}

class _LoginView extends StatefulWidget {
  const _LoginView({this.initialEmail});

  final String? initialEmail;

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _password = TextEditingController();
  bool _passwordVisible = false;
  String? _localError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _login() {
    if (!Validators.email(_email.text) || _password.text.isEmpty) {
      setState(() => _localError = context.l10n.loginInvalidInput);
      return;
    }
    setState(() => _localError = null);
    context.read<LoginCubit>().login(Validators.normalizeEmail(_email.text), _password.text);
  }

  void _forgot() {
    if (!Validators.email(_email.text)) {
      setState(() => _localError = context.l10n.loginEnterEmailFirst);
      return;
    }
    setState(() => _localError = null);
    context.read<SendCodeCubit>().send(
      email: Validators.normalizeEmail(_email.text),
      purpose: OtpPurpose.forgotPassword,
      language: context.languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MultiBlocListener(
      listeners: [
        BlocListener<LoginCubit, SubmitState<AppUser>>(
          listener: (context, state) {
            if (state.status == SubmitStatus.success) {
              context.read<SessionCubit>().signedIn(state.result!);
            }
          },
        ),
        BlocListener<SendCodeCubit, SubmitState<OtpSendResult>>(
          listener: (context, state) {
            if (state.status != SubmitStatus.success) return;
            context.push(
              Routes.forgotOtp,
              extra: OnboardingDraft(
                email: Validators.normalizeEmail(_email.text),
                purpose: OtpPurpose.forgotPassword,
                resendAfter: state.result?.resendAfter ?? 60,
              ),
            );
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          final login = context.watch<LoginCubit>().state;
          final send = context.watch<SendCodeCubit>().state;
          final error =
              _localError ??
              [login, send]
                  .where((state) => state.status == SubmitStatus.failure)
                  .map((state) => errorMessage(context, state.error!))
                  .firstOrNull;
          return AuthBackdrop(
            image: AppAssets.signinBackground,
            artOnTop: true,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthTop(),
                  SizedBox(height: MediaQuery.sizeOf(context).height * .36),
                  Text(
                    l10n.loginTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.loginSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, fontSize: 16),
                  ),
                  const SizedBox(height: 26),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      hintText: l10n.loginEmailHint,
                      prefixIcon: const Icon(LucideIcons.mail, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: !_passwordVisible,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      hintText: l10n.loginPasswordHint,
                      prefixIcon: const Icon(LucideIcons.lockKeyhole, color: AppColors.ink),
                      suffixIcon: IconButton(
                        tooltip: _passwordVisible ? l10n.hidePassword : l10n.showPassword,
                        onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                        icon: Icon(
                          _passwordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error, style: const TextStyle(color: AppColors.error)),
                  ],
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: send.busy ? null : _forgot,
                      child: Text(l10n.loginForgot),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GradientButton(
                    login.busy ? l10n.loginBusy : l10n.loginButton,
                    busy: login.busy,
                    onPressed: _login,
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => context.push(Routes.registerEmail),
                    child: Text(l10n.loginCreateAccount),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
