import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/utils/submit_cubit.dart';
import '../../../../core/utils/submit_state.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/session_cubit.dart';
import '../../domain/profile_repository.dart';
import '../bloc/avatars_cubit.dart';
import '../widgets/character_avatar.dart';

/// `PATCH /me { name, avatarId }`.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => AvatarsCubit(sl())..load()),
      BlocProvider(create: (_) => SubmitCubit<AppUser>()),
    ],
    child: const _EditProfileView(),
  );
}

class _EditProfileView extends StatefulWidget {
  const _EditProfileView();

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  late final AppUser _user = context.read<SessionCubit>().state.user!;
  late final _name = TextEditingController(text: _user.name);
  late int? _avatarId = _user.avatarId;
  bool _showErrors = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (!Validators.displayName(name)) {
      setState(() => _showErrors = true);
      return;
    }
    final changedName = name == _user.name ? null : name;
    final changedAvatar = _avatarId == _user.avatarId ? null : _avatarId;
    if (changedName == null && changedAvatar == null) {
      Navigator.of(context).pop();
      return;
    }
    context.read<SubmitCubit<AppUser>>().run(
      () => sl<ProfileRepository>().updateProfile(name: changedName, avatarId: changedAvatar),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<SubmitCubit<AppUser>, SubmitState<AppUser>>(
      listener: (context, state) {
        if (state.status == SubmitStatus.success) {
          context.read<SessionCubit>().userUpdated(state.result!);
          showAppSnackBar(context, l10n.editProfileSaved);
          Navigator.of(context).pop();
        } else if (state.status == SubmitStatus.failure) {
          showErrorSnackBar(context, state.error!);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.editProfileTitle)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  maxLength: 60,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => _showErrors ? setState(() {}) : null,
                  decoration: InputDecoration(
                    labelText: l10n.editProfileName,
                    counterText: '',
                    errorText: _showErrors && !Validators.displayName(_name.text)
                        ? l10n.editProfileNameInvalid
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: BlocBuilder<AvatarsCubit, List<Avatar>>(
                    builder: (context, avatars) => CharacterGrid(
                      avatars: avatars,
                      selected: _avatarId,
                      onSelected: (id) => setState(() => _avatarId = id),
                    ),
                  ),
                ),
                BlocBuilder<SubmitCubit<AppUser>, SubmitState<AppUser>>(
                  builder: (context, state) => GradientButton(
                    l10n.commonSave,
                    icon: Icons.check,
                    busy: state.busy,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
