import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../services/secure_storage_service.dart';
import '../../../../services/ads/ad_service.dart';
import '../../../../shared/models/giveaway.dart';
import '../../../../shared/repositories/giveaway_repository.dart';
import '../../../../shared/repositories/participation_repository.dart';
import '../../../../shared/repositories/user_repository.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../../../number_reveal/presentation/number_reveal_page.dart';
import '../bloc/participation_cubit.dart';
import '../bloc/participation_state.dart';
import '../widgets/registration_form.dart';

/// Registration, explicit optional rewarded-ad choice, server-authoritative
/// entry, then the existing number reveal.
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
        showRewardedAd: () => getIt.isRegistered<AdService>()
            ? getIt<AdService>().showRewarded()
            : Future.value(false),
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
  bool _navigatedToReveal = false;
  bool _rewardDialogShown = false;
  AdService? _ads;
  @override
  void initState() {
    super.initState();
    if (getIt.isRegistered<AdService>()) {
      _ads = getIt<AdService>();
      _ads!.frequency.criticalFlows++;
    }
  }

  @override
  void dispose() {
    if (_ads != null) _ads!.frequency.criticalFlows--;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l10n.participationJoinGiveaway)),
      body: BlocConsumer<ParticipationCubit, ParticipationState>(
        listenWhen: (previous, current) =>
            (current.step == ParticipationStep.readyToJoin && !_rewardDialogShown) ||
            (current.step == ParticipationStep.success ||
                    current.step == ParticipationStep.alreadyParticipating) &&
                !_navigatedToReveal,
        listener: (context, state) async {
          if (state.step == ParticipationStep.readyToJoin) {
            _rewardDialogShown = true;
            final watch = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => RewardFrameChoiceDialog(
                onClose: () => Navigator.of(dialogContext).pop(false),
                onWatch: () => Navigator.of(dialogContext).pop(true),
              ),
            );
            if (!context.mounted) return;
            if (watch == true) {
              await context.read<ParticipationCubit>().joinWithRewardedAd();
            } else {
              await context.read<ParticipationCubit>().joinWithoutAd();
            }
            return;
          }
          _navigatedToReveal = true;
          if (state.step == ParticipationStep.alreadyParticipating) {
            Navigator.of(context).pop(state.participationNumber);
            return;
          }
          final result = await Navigator.of(context).push<int>(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => NumberRevealPage(
                participationId: state.participationId!,
                participationNumber: state.participationNumber!,
                rewardedFrameUnlocked: state.rewardedFrameUnlocked,
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

            case ParticipationStep.readyToJoin:
              return _StatusView(
                icon: Icons.confirmation_number_rounded,
                label: l10n.participationGeneratingNumber,
              );

            case ParticipationStep.showingRewardedAd:
              return _StatusView(
                icon: Icons.ondemand_video_rounded,
                label: l10n.participationGeneratingNumber,
              );

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
            case ParticipationStep.participationCreated:
              return _StatusView(
                icon: Icons.check_circle_rounded,
                label: l10n.participationSuccessOpening,
              );

            case ParticipationStep.alreadyParticipating:
              return const Center(child: CircularProgressIndicator());

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

class RewardFrameChoiceDialog extends StatelessWidget {
  const RewardFrameChoiceDialog({super.key, required this.onClose, required this.onWatch});

  final VoidCallback onClose;
  final VoidCallback onWatch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                ),
              ),
              Text(
                l10n.rewardFrameDialogTitle,
                textAlign: TextAlign.center,
                style: AppTypography.headlineMd.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.rewardFrameDialogDescription,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryGradientButton(label: l10n.rewardFrameWatchAd, onPressed: onWatch),
            ],
          ),
        ),
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
