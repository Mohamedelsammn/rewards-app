import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/winner.dart';
import '../../../shared/repositories/participation_repository.dart';
import '../../../shared/repositories/winner_repository.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/primary_gradient_button.dart';
import '../../giveaway_details/presentation/giveaway_details_page.dart';

/// The winner experience, distinct from the (bottom-anchored) participation-
/// number-generated celebration: this one bursts from the TOP of the screen
/// with a large animated "WINNER" headline. Fires exactly once per win --
/// [Winner.celebrationAcknowledgedAt] is the server-authoritative gate, set
/// only when the user dismisses this page, so a win is never lost to a
/// mistimed app close and never replays after being seen.
class WinnerCelebrationPage extends StatefulWidget {
  const WinnerCelebrationPage({super.key, required this.winner});

  final Winner winner;

  @override
  State<WinnerCelebrationPage> createState() => _WinnerCelebrationPageState();
}

class _WinnerCelebrationPageState extends State<WinnerCelebrationPage> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.heavyImpact();
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _acknowledge({bool viewGiveaway = false}) async {
    await getIt<WinnerRepository>().acknowledgeCelebration(widget.winner.id);
    // The winning giveaway just transitioned to `ended` server-side -- clear
    // the cached My Giveaways list so it doesn't keep showing stale
    // active/unresolved state for up to CacheKeys.myParticipationsTtl.
    await getIt<ParticipationRepository>().invalidateMyParticipations();
    if (!mounted) return;
    Navigator.of(context).pop();
    if (viewGiveaway) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GiveawayDetailsPage(giveawayId: widget.winner.giveawayId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _acknowledge();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(color: AppColors.inverseSurface.withValues(alpha: 0.7)),
              ),
            ),
            // Celebration burst anchored to the TOP -- the distinguishing
            // trait of the winner experience vs. the participation reveal.
            Align(
              alignment: Alignment.topCenter,
              child: IgnorePointer(
                child: SizedBox(
                  height: 320,
                  child: Lottie.asset('assets/lottie/Celebration.json', repeat: false),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: IgnorePointer(
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: 1.5708,
                  emissionFrequency: 0.05,
                  numberOfParticles: 30,
                  maxBlastForce: 20,
                  minBlastForce: 8,
                  gravity: 0.3,
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
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.containerPadding,
                    vertical: AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => AppColors.gradientGold.createShader(bounds),
                        child: Text(
                          l10n.winnerCelebrationTitle,
                          textAlign: TextAlign.center,
                          style: AppTypography.display.copyWith(
                            color: Colors.white,
                            fontSize: 52,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.winnerCelebrationCongratulations,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyLg.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: AppNetworkImage(
                                url: widget.winner.giveawayImageUrl,
                                borderRadius: BorderRadius.circular(AppRadius.chip),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Text(
                                widget.winner.giveawayTitle ?? l10n.winnerCelebrationYourPrize,
                                style: AppTypography.headlineMd.copyWith(fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      PrimaryGradientButton(
                        label: l10n.winnerCelebrationViewPrize,
                        icon: Icons.card_giftcard_rounded,
                        gradient: AppColors.gradientGold,
                        onPressed: () => _acknowledge(viewGiveaway: true),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () => _acknowledge(),
                        child: Text(
                          l10n.winnerCelebrationDismiss,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
