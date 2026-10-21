import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/submit_cubit.dart';
import '../../../../core/utils/submit_state.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/bloc/session_cubit.dart';
import '../../../auth/presentation/widgets/password_fields.dart';
import '../../domain/profile_repository.dart';

/// `DELETE /me { password }` → deletion after the grace period. The user is
/// signed out locally once the request is accepted.
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<SubmitCubit<int>>();
    final confirmed = await showAppConfirmDialog(
      context,
      icon: LucideIcons.trash2,
      title: l10n.deleteAccountConfirmTitle,
      message: l10n.deleteAccountConfirmMessage,
      confirmLabel: l10n.deleteAccountButton,
      destructive: true,
    );
    if (!confirmed) return;
    await cubit.run(() => sl<ProfileRepository>().requestAccountDeletion(_password.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) => SubmitCubit<int>(),
      child: BlocConsumer<SubmitCubit<int>, SubmitState<int>>(
        listener: (context, state) async {
          if (state.status == SubmitStatus.success) {
            final session = context.read<SessionCubit>();
            await showAppInfoDialog(
              context,
              title: l10n.deleteAccountTitle,
              message: l10n.deleteAccountDone(state.result ?? 14),
            );
            await session.endLocally();
          } else if (state.status == SubmitStatus.failure) {
            showErrorSnackBar(context, state.error!);
          }
        },
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: Text(l10n.deleteAccountTitle)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Icon(LucideIcons.triangleAlert, size: 64, color: AppColors.danger),
                const SizedBox(height: 18),
                Text(
                  l10n.deleteAccountBody,
                  style: const TextStyle(color: AppColors.ink, fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 24),
                PasswordField(
                  controller: _password,
                  label: l10n.deleteAccountPassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: state.busy || _password.text.isEmpty ? null : () => _submit(context),
                  icon: state.busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(LucideIcons.trash2),
                  label: Text(l10n.deleteAccountButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
