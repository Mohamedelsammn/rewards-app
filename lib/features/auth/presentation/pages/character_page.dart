import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/localization/error_messages.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/submit_state.dart';
import '../../../../core/widgets/auth_top.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../profile/domain/profile_repository.dart';
import '../../../profile/presentation/bloc/avatars_cubit.dart';
import '../../../profile/presentation/widgets/character_avatar.dart';
import '../../domain/entities/app_user.dart';
import '../bloc/auth_flow_cubits.dart';
import '../bloc/session_cubit.dart';
import '../onboarding_draft.dart';

/// Step 4: pick a character, then `POST /auth/register`.
class CharacterPage extends StatelessWidget {
  const CharacterPage({required this.draft, super.key});

  final OnboardingDraft draft;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => RegisterCubit(sl())),
      BlocProvider(create: (_) => AvatarsCubit(sl())..load()),
    ],
    child: _CharacterView(draft: draft),
  );
}

class _CharacterView extends StatefulWidget {
  const _CharacterView({required this.draft});

  final OnboardingDraft draft;

  @override
  State<_CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<_CharacterView> {
  int _selected = 1;

  void _register() => context.read<RegisterCubit>().register(
    email: widget.draft.email,
    verificationToken: widget.draft.verificationToken!,
    password: widget.draft.password!,
    avatarId: _selected,
    language: context.languageCode,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<RegisterCubit, SubmitState<AppUser>>(
      listener: (context, state) {
        if (state.status == SubmitStatus.success) {
          // The router redirects to Home once the session is authenticated.
          context.read<SessionCubit>().signedIn(state.result!);
        } else if (state.status == SubmitStatus.failure && requiresRestart(state.error)) {
          showErrorSnackBar(context, state.error!);
          context.go(Routes.registerEmail);
        }
      },
      builder: (context, state) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppGradients.character),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const AuthTop(step: 3),
                  const SizedBox(height: 35),
                  Text(
                    l10n.characterTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.characterSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, fontSize: 17),
                  ),
                  const SizedBox(height: 26),
                  Expanded(
                    child: BlocBuilder<AvatarsCubit, List<Avatar>>(
                      builder: (context, avatars) => CharacterGrid(
                        avatars: avatars,
                        selected: _selected,
                        onSelected: (id) => setState(() => _selected = id),
                      ),
                    ),
                  ),
                  if (state.status == SubmitStatus.failure) ...[
                    Text(
                      errorMessage(context, state.error!),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    TextButton(
                      onPressed: () => context.go(Routes.login),
                      child: Text(l10n.emailLoginInstead),
                    ),
                  ],
                  GradientButton(l10n.commonContinue, busy: state.busy, onPressed: _register),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
