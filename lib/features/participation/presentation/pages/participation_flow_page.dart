import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../services/secure_storage_service.dart';
import '../../../../shared/models/giveaway.dart';
import '../../../../shared/repositories/giveaway_repository.dart';
import '../../../../shared/repositories/participation_repository.dart';
import '../../../../shared/repositories/user_repository.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../../../scratch_card/presentation/scratch_card_page.dart';
import '../bloc/participation_cubit.dart';
import '../bloc/participation_state.dart';
import '../widgets/registration_form.dart';

/// Orchestrates the full participation flow's UI: registration (if needed)
/// -> direct server-side participation creation (no ad step -- V1 has no
/// advertisement system) -> hand-off to Scratch Card -> pops back to
/// Giveaway Details with the revealed number as the result
/// (implementation-plan.md §3, tasks.md T10-06).
class ParticipationFlowPage extends StatelessWidget {
  const ParticipationFlowPage({super.key, required this.giveaway});

  final Giveaway giveaway;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ParticipationCubit(
        giveawayId: giveaway.id,
        secureStorage: getIt<SecureStorageService>(),
        userRepository: getIt<UserRepository>(),
        participationRepository: getIt<ParticipationRepository>(),
        giveawayRepository: getIt<GiveawayRepository>(),
      )..start(),
      child: const _ParticipationFlowView(),
    );
  }
}

class _ParticipationFlowView extends StatefulWidget {
  const _ParticipationFlowView();

  @override
  State<_ParticipationFlowView> createState() => _ParticipationFlowViewState();
}

class _ParticipationFlowViewState extends State<_ParticipationFlowView> {
  bool _navigatedToScratchCard = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l10n.participationJoinGiveaway)),
      body: BlocConsumer<ParticipationCubit, ParticipationState>(
        listenWhen: (previous, current) =>
            current.step == ParticipationStep.success && !_navigatedToScratchCard,
        listener: (context, state) async {
          _navigatedToScratchCard = true;
          final result = await Navigator.of(context).push<int>(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => ScratchCardPage(
                participationId: state.participationId!,
                participationNumber: state.participationNumber!,
              ),
            ),
          );
          if (context.mounted) {
            Navigator.of(context).pop(result ?? state.participationNumber);
          }
        },
        builder: (context, state) {
          switch (state.step) {
            case ParticipationStep.checkingIdentity:
            case ParticipationStep.submittingRegistration:
              return const Center(child: CircularProgressIndicator());

            case ParticipationStep.needsRegistration:
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.containerPadding),
                child: Center(
                  child: SingleChildScrollView(
                    child: RegistrationForm(
                      isSubmitting: false,
                      onSubmit: (fullName, phone, countryCode) {
                        context.read<ParticipationCubit>().submitRegistration(
                          fullName: fullName,
                          phone: phone,
                          countryCode: countryCode,
                        );
                      },
                    ),
                  ),
                ),
              );

            case ParticipationStep.creatingParticipation:
              return _StatusView(
                icon: Icons.confirmation_number_rounded,
                label: l10n.participationGeneratingNumber,
              );

            case ParticipationStep.success:
              return _StatusView(
                icon: Icons.check_circle_rounded,
                label: l10n.participationSuccessOpening,
              );

            case ParticipationStep.failure:
              return _FailureView(
                message: state.failure?.localize(l10n) ?? l10n.commonSomethingWrong,
                onRetry: () => context.read<ParticipationCubit>().retry(),
              );
          }
        },
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.primary),
          const SizedBox(height: AppSpacing.lg),
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.lg),
          Text(label, style: AppTypography.bodyLg),
        ],
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.containerPadding),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: AppTypography.bodyMd, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            PrimaryGradientButton(label: l10n.participationTryAgain, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
