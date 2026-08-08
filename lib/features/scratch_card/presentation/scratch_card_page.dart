import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/repositories/participation_repository.dart';
import '../../../shared/widgets/primary_gradient_button.dart';
import 'cubit/scratch_card_cubit.dart';
import 'cubit/scratch_card_state.dart';
import 'widgets/scratch_card_widget.dart';

/// Pure presentation: the participation number is already persisted server-
/// side by the time this page is shown (implementation-plan.md §20). The
/// celebration.json animation bursts up from the bottom on reveal per the
/// brief's "participation number generated" experience -- distinct from the
/// (deferred) top-anchored winner-celebration experience.
class ScratchCardPage extends StatelessWidget {
  const ScratchCardPage({
    super.key,
    required this.participationId,
    required this.participationNumber,
  });

  final String participationId;
  final int participationNumber;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScratchCardCubit(),
      child: _ScratchCardView(
        participationId: participationId,
        participationNumber: participationNumber,
      ),
    );
  }
}

class _ScratchCardView extends StatefulWidget {
  const _ScratchCardView({required this.participationId, required this.participationNumber});

  final String participationId;
  final int participationNumber;

  @override
  State<_ScratchCardView> createState() => _ScratchCardViewState();
}

class _ScratchCardViewState extends State<_ScratchCardView> {
  late final ConfettiController _confettiController;
  bool _celebrationFired = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _onRevealed() {
    if (_celebrationFired) return;
    _celebrationFired = true;
    HapticFeedback.mediumImpact();
    _confettiController.play();
    getIt<ParticipationRepository>().markScratchRevealed(widget.participationId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formattedNumber = widget.participationNumber.toString().padLeft(4, '0');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: AppColors.inverseSurface.withValues(alpha: 0.55)),
            ),
          ),
          BlocConsumer<ScratchCardCubit, ScratchCardState>(
            listenWhen: (previous, current) => !previous.isRevealed && current.isRevealed,
            listener: (context, state) => _onRevealed(),
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.containerPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AppSpacing.lg),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l10n.scratchCardYourLuckyNumber, style: AppTypography.headlineMd),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: 260,
                            height: 160,
                            child: ScratchCardWidget(
                              isRevealed: state.isRevealed,
                              onProgressChanged: (percent) =>
                                  context.read<ScratchCardCubit>().updateProgress(percent),
                              child: DecoratedBox(
                                decoration: const BoxDecoration(gradient: AppColors.gradientGold),
                                child: Center(
                                  child: Text(
                                    formattedNumber,
                                    style: AppTypography.display.copyWith(
                                      color: Colors.white,
                                      fontSize: 44,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (state.isRevealed)
                            SizedBox(
                              width: double.infinity,
                              child: PrimaryGradientButton(
                                label: l10n.scratchCardViewInMyGiveaways,
                                icon: Icons.arrow_forward_rounded,
                                onPressed: () =>
                                    Navigator.of(context).pop(widget.participationNumber),
                              ),
                            )
                          else
                            Text(
                              l10n.scratchCardScratchToReveal,
                              style: AppTypography.bodyMd,
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Celebration burst anchored to the bottom, non-blocking.
          Align(
            alignment: Alignment.bottomCenter,
            child: IgnorePointer(
              child: SizedBox(
                height: 260,
                child: Lottie.asset(
                  'assets/lottie/Celebration.json',
                  controller: null,
                  repeat: false,
                  animate: _celebrationFired,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: -1.5708, // straight up
                emissionFrequency: 0.04,
                numberOfParticles: 24,
                maxBlastForce: 22,
                minBlastForce: 10,
                gravity: 0.25,
                shouldLoop: false,
                colors: const [
                  AppColors.primary,
                  AppColors.secondary,
                  AppColors.goldAccent,
                  AppColors.success,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
