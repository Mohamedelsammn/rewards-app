import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/repositories/participation_repository.dart';
import '../../../shared/widgets/primary_gradient_button.dart';
import '../../../shared/widgets/participation_reward_frame.dart';

/// Replaces the old scratch-card interaction entirely: the participation
/// number is already persisted server-side by the time this page is shown
/// (create-participation / fn_create_participation), so there is nothing to
/// "unlock" here -- this is a pure celebratory reveal, not a gate.
///
/// number-generator.json loops above the code; the code itself fades/scales
/// in a beat after the page appears so it still reads as a "reveal" without
/// requiring any user interaction (scratching, tapping, etc.).
class NumberRevealPage extends StatefulWidget {
  const NumberRevealPage({
    super.key,
    required this.participationId,
    required this.participationNumber,
    this.rewardedFrameUnlocked = false,
  });

  final String participationId;
  final int participationNumber;
  final bool rewardedFrameUnlocked;

  @override
  State<NumberRevealPage> createState() => _NumberRevealPageState();
}

class _NumberRevealPageState extends State<NumberRevealPage> {
  bool _numberVisible = false;
  bool _hasRewardFrame = false;

  @override
  void initState() {
    super.initState();
    _hasRewardFrame = widget.rewardedFrameUnlocked;
    // Server-authoritative: this only marks that the device has seen the
    // number (analytics/UX bookkeeping), never re-derives or re-requests it.
    getIt<ParticipationRepository>().markNumberRevealed(widget.participationId);
    HapticFeedback.mediumImpact();
    // A short beat before the reveal animation starts -- long enough to
    // read as intentional, short enough to never feel like a loading delay.
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _numberVisible = true);
    });
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
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.containerPadding),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  constraints: const BoxConstraints(maxWidth: 360),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppSpacing.lg),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.numberRevealTitle,
                        style: AppTypography.headlineMd,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.numberRevealSubtitle,
                        style: AppTypography.bodyMd,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: 200,
                        child: Lottie.asset(
                          'assets/lottie/number-generator.json',
                          repeat: true,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AnimatedOpacity(
                        opacity: _numberVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOut,
                        child: AnimatedScale(
                          scale: _numberVisible ? 1 : 0.82,
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutBack,
                          child: ParticipationRewardFrame(
                            enabled: _hasRewardFrame,
                            borderRadius: AppSpacing.lg,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.gradientGold,
                                borderRadius: BorderRadius.circular(AppSpacing.lg),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.goldAccent.withValues(alpha: 0.35),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Text(
                                formattedNumber,
                                textAlign: TextAlign.center,
                                style: AppTypography.display.copyWith(
                                  color: Colors.white,
                                  fontSize: 48,
                                  letterSpacing: 6,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryGradientButton(
                          label: l10n.numberRevealViewInMyGiveaways,
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () => Navigator.of(context).pop(widget.participationNumber),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
