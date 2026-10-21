import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/models/eligible_participant.dart';
import '../../../../shared/models/winner.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../bloc/giveaway_analytics_cubit.dart';
import '../bloc/giveaway_analytics_state.dart';
import 'wheel_segments.dart';
import 'winner_wheel.dart';

enum _WheelPhase { selecting, spinning, revealing, error }

/// Wheel-of-fortune presentation for winner selection, shown by
/// [GiveawayAnalyticsPage] as an OVERLAY on top of itself (inside a Stack,
/// behind a blurred backdrop) -- never pushed as a separate route. The
/// caller owns the backdrop and removes this widget from its Stack when
/// [onClose] fires; this widget never touches the Navigator.
///
/// IMPORTANT: this widget never decides the winner. It calls the exact same
/// server-authoritative [GiveawayAnalyticsCubit.selectWinner] the app
/// already used for manual selection -- with [manualTarget]'s
/// participation id if the admin pre-selected someone from the picker
/// sheet, or no id at all for the normal random path -- and only animates
/// toward whatever winner the server actually returns. The wheel is purely
/// a presentation layer on top of an already-final result.
///
/// [cubit] is passed explicitly (not read from context) since it's handed
/// down from the page's own `BlocProvider` at the call site -- same
/// reasoning as the existing participant picker sheet.
class WinnerWheelOverlay extends StatefulWidget {
  const WinnerWheelOverlay({
    super.key,
    required this.cubit,
    required this.giveawayId,
    required this.decoyPool,
    required this.onClose,
    this.manualTarget,
  });

  final GiveawayAnalyticsCubit cubit;
  final String giveawayId;

  /// Already-loaded client data (Recent Participants) used purely as
  /// decorative wheel entries -- never the actual selection mechanism, and
  /// never a fresh full-participant-list fetch just to populate the wheel.
  final List<RecentParticipant> decoyPool;

  /// The admin's pending manual pick, if any. When set, this participant is
  /// guaranteed to be who the wheel lands on; when null, the server picks
  /// randomly. Both cases drive this widget identically from here on.
  final EligibleParticipant? manualTarget;

  /// Called once the admin is done with the overlay (reveal acknowledged, or
  /// an error dismissed) so the caller can remove it from its Stack.
  final VoidCallback onClose;

  @override
  State<WinnerWheelOverlay> createState() => _WinnerWheelOverlayState();
}

class _WinnerWheelOverlayState extends State<WinnerWheelOverlay> {
  _WheelPhase _phase = _WheelPhase.selecting;
  List<String> _segments = const [];
  int _winningIndex = 0;
  Winner? _winner;

  @override
  void initState() {
    super.initState();
    _startSelection();
  }

  Future<void> _startSelection() async {
    final succeeded = await widget.cubit.selectWinner(
      widget.giveawayId,
      participationId: widget.manualTarget?.participationId,
    );
    if (!mounted) return;

    final winner = succeeded ? widget.cubit.state.lastSelectedWinner : null;
    if (winner == null) {
      setState(() => _phase = _WheelPhase.error);
      return;
    }

    final built = buildWheelSegments(
      winnerLabel: winner.formattedParticipationNumber,
      decoyLabels: widget.decoyPool.map((p) => p.formattedParticipationNumber).toList(),
    );
    setState(() {
      _winner = winner;
      _segments = built.labels;
      _winningIndex = built.winningIndex;
      _phase = _WheelPhase.spinning;
    });
  }

  void _onSpinComplete() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _phase = _WheelPhase.revealing);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.containerPadding),
          child: switch (_phase) {
            _WheelPhase.selecting => _SelectingView(l10n: l10n),
            _WheelPhase.spinning => AspectRatio(
              aspectRatio: 1,
              child: WinnerWheel(
                key: ValueKey(_segments),
                segments: _segments,
                winningIndex: _winningIndex,
                onSpinComplete: _onSpinComplete,
              ),
            ),
            _WheelPhase.revealing => _WinnerRevealView(winner: _winner!, onDone: widget.onClose),
            _WheelPhase.error => _WheelErrorView(
              message: widget.cubit.state.failure?.localize(l10n),
              onClose: widget.onClose,
            ),
          },
        ),
      ),
    );
  }
}

class _SelectingView extends StatelessWidget {
  const _SelectingView({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: AppColors.goldAccent),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.giveawayAnalyticsSelecting,
          style: AppTypography.bodyLg.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}

/// The reveal sequence: a short pause already happened before this view
/// mounts (see [_WinnerWheelOverlayState._onSpinComplete]), then here: the
/// celebration Lottie starts immediately, "WINNER" scales/fades in, and the
/// (slightly larger than the inline analytics card) winner card follows
/// shortly after -- reusing the existing `Celebration.json` asset, never a
/// new one.
class _WinnerRevealView extends StatefulWidget {
  const _WinnerRevealView({required this.winner, required this.onDone});
  final Winner winner;
  final VoidCallback onDone;

  @override
  State<_WinnerRevealView> createState() => _WinnerRevealViewState();
}

class _WinnerRevealViewState extends State<_WinnerRevealView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _titleAnim;
  late final Animation<double> _cardAnim;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _titleAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
    );
    _cardAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IgnorePointer(
            child: SizedBox(
              height: 220,
              child: Lottie.asset('assets/lottie/Celebration.json', repeat: false),
            ),
          ),
          AnimatedBuilder(
            animation: _titleAnim,
            builder: (context, child) => Transform.scale(
              scale: 0.6 + (0.4 * _titleAnim.value.clamp(0.0, 1.0)),
              child: Opacity(opacity: _titleAnim.value.clamp(0.0, 1.0), child: child),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => AppColors.gradientGold.createShader(bounds),
              child: Text(
                l10n.winnerCelebrationTitle,
                style: AppTypography.display.copyWith(
                  color: Colors.white,
                  fontSize: 48,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedBuilder(
            animation: _cardAnim,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, 24 * (1 - _cardAnim.value.clamp(0.0, 1.0))),
              child: Opacity(opacity: _cardAnim.value.clamp(0.0, 1.0), child: child),
            ),
            child: _WheelWinnerCard(winner: widget.winner),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryGradientButton(
            label: l10n.giveawayAnalyticsWheelDoneAction,
            icon: Icons.check_rounded,
            gradient: AppColors.gradientGold,
            onPressed: widget.onDone,
          ),
        ],
      ),
    );
  }
}

/// A larger, more dramatic take on the analytics page's inline winner card --
/// same gold gradient/trophy language, bigger type, centered for a "reveal
/// moment" feel rather than a list-item feel.
class _WheelWinnerCard extends StatelessWidget {
  const _WheelWinnerCard({required this.winner});
  final Winner winner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.gradientGold,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldAccent.withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 32),
          const SizedBox(height: AppSpacing.xs),
          Text(
            winner.rank <= 1
                ? l10n.giveawayAnalyticsWinnerLabel.toUpperCase()
                : l10n.giveawayAnalyticsWinnerRank(winner.rank).toUpperCase(),
            style: AppTypography.labelSm.copyWith(color: Colors.white, letterSpacing: 1.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            winner.formattedParticipationNumber,
            style: AppTypography.display.copyWith(
              color: Colors.white,
              fontSize: 52,
              letterSpacing: 6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          if (winner.fullName != null && winner.fullName!.isNotEmpty)
            Text(
              winner.fullName!,
              style: AppTypography.bodyLg.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (winner.phoneE164 != null && winner.phoneE164!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              winner.phoneE164!,
              style: AppTypography.bodyMd.copyWith(color: Colors.white.withValues(alpha: 0.85)),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _WheelErrorView extends StatelessWidget {
  const _WheelErrorView({required this.message, required this.onClose});
  final String? message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 40),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.giveawayAnalyticsWheelErrorTitle,
          style: AppTypography.headlineMd.copyWith(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            message!,
            style: AppTypography.bodyMd.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryGradientButton(
          label: l10n.commonDismiss,
          icon: Icons.close_rounded,
          gradient: AppColors.gradientPrimary,
          onPressed: onClose,
        ),
      ],
    );
  }
}
