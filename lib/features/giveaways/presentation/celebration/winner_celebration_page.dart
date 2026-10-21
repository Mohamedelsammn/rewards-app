import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../domain/entities/giveaway_entities.dart';
import '../../domain/repositories/giveaways_repository.dart';
import '../widgets/giveaway_visuals.dart';
import 'claim_sheet.dart';

/// Full-screen winner celebration. Acknowledged as soon as it is shown so it
/// is not repeated; the prize can be claimed now or later from My Giveaways.
class WinnerCelebrationPage extends StatefulWidget {
  const WinnerCelebrationPage({required this.winning, super.key});

  final Winning winning;

  @override
  State<WinnerCelebrationPage> createState() => _WinnerCelebrationPageState();
}

class _WinnerCelebrationPageState extends State<WinnerCelebrationPage> {
  final _repository = sl<GiveawaysRepository>();
  late Winning _winning = widget.winning;

  @override
  void initState() {
    super.initState();
    _repository.acknowledgeCelebration(widget.winning.id).catchError((_) {});
  }

  Future<void> _claim() async {
    final claimed = await showClaimSheet(context, _winning);
    if (claimed != null && mounted) setState(() => _winning = claimed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      backgroundColor: AppColors.pale,
      body: SafeArea(
        child: Stack(
          children: [
            if (!reduceMotion)
              Positioned.fill(
                child: IgnorePointer(
                  child: Lottie.asset(
                    AppAssets.celebrationLottie,
                    repeat: false,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: GiveawayArt(
                    imageUrl: _winning.imageUrl,
                    title: _winning.title,
                    prize: _winning.prize,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.celebrationTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineLarge?.copyWith(color: AppColors.violet),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.celebrationBody(
                    _winning.prize.of(context).isNotEmpty
                        ? _winning.prize.of(context)
                        : _winning.title.of(context),
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.celebrationNumber(_winning.participationNumber),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 15),
                ),
                if (_winning.claimDeadline != null && _winning.canClaim) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.claimDeadline(Formatters.date(context, _winning.claimDeadline!)),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 30),
                if (_winning.canClaim) ...[
                  GradientButton(
                    l10n.celebrationClaim,
                    icon: Icons.card_giftcard,
                    onPressed: _claim,
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.celebrationLater),
                  ),
                ] else ...[
                  if (_winning.status == WinningStatus.claimed)
                    Text(
                      l10n.claimDone,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.success),
                    ),
                  const SizedBox(height: 16),
                  GradientButton(l10n.commonDone, onPressed: () => Navigator.pop(context)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
