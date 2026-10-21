import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/utils/submit_cubit.dart';
import '../../../../core/utils/submit_state.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/widgets/password_fields.dart';

/// `POST /auth/password/change`. The server revokes the other sessions and
/// keeps this one.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  bool get _valid => _current.text.isNotEmpty && Validators.passwordAcceptable(_next.text);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) => SubmitCubit<void>(),
      child: BlocConsumer<SubmitCubit<void>, SubmitState<void>>(
        listener: (context, state) {
          if (state.status == SubmitStatus.success) {
            showAppSnackBar(context, l10n.changePasswordDone);
            Navigator.of(context).pop();
          } else if (state.status == SubmitStatus.failure) {
            showErrorSnackBar(context, state.error!);
          }
        },
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: Text(l10n.changePasswordTitle)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                PasswordField(
                  controller: _current,
                  label: l10n.changePasswordCurrent,
                  autofillHints: const [AutofillHints.password],
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                PasswordField(
                  controller: _next,
                  label: l10n.changePasswordNew,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                PasswordRules(password: _next.text),
                const SizedBox(height: 24),
                GradientButton(
                  l10n.commonSave,
                  icon: Icons.check,
                  busy: state.busy,
                  onPressed: _valid
                      ? () => context.read<SubmitCubit<void>>().run(
                          () => sl<AuthRepository>().changePassword(
                            currentPassword: _current.text,
                            newPassword: _next.text,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
