import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/gradient_button.dart';

/// "Not Enough Points" for any reward flow. [balance] and [required] come
/// from the wallet state and the reward; the shortfall is computed only for
/// display. [onEarnPoints] adds a secondary action and should be passed only
/// when that destination is available (e.g. rewarded ads enabled).
Future<void> showInsufficientPointsDialog(
  BuildContext context, {
  required int balance,
  required int required,
  VoidCallback? onEarnPoints,
}) => showAppDialog<void>(
  context,
  builder: (dialogContext) => InsufficientPointsDialog(
    balance: balance,
    required: required,
    onEarnPoints: onEarnPoints == null
        ? null
        : () {
            Navigator.of(dialogContext).pop();
            onEarnPoints();
          },
  ),
);

class InsufficientPointsDialog extends StatelessWidget {
  const InsufficientPointsDialog({
    required this.balance,
    required this.required,
    this.onEarnPoints,
    super.key,
  });

  final int balance;
  final int required;
  final VoidCallback? onEarnPoints;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final missing = (required - balance).clamp(0, required);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ExcludeSemantics(child: _WalletBadge()),
          const SizedBox(height: 18),
          Text(
            l10n.redeemInsufficientTitleCaps,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.ink, fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.redeemInsufficientMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 14.5, height: 1.45),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            decoration: BoxDecoration(
              color: AppColors.shortfallRow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  key: const ValueKey('shortfall-balance'),
                  icon: LucideIcons.wallet,
                  label: l10n.redeemYourBalance,
                  points: balance,
                ),
                const Divider(height: 1, color: AppColors.divider),
                _SummaryRow(
                  key: const ValueKey('shortfall-required'),
                  icon: LucideIcons.tag,
                  label: l10n.redeemRequired,
                  points: required,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            key: const ValueKey('shortfall-missing'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.shortfallMissing,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.circleAlert,
                  size: 18,
                  color: AppColors.shortfallMissingText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.redeemMissing,
                    style: const TextStyle(
                      color: AppColors.shortfallMissingText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  l10n.pointsAmount(Formatters.points(missing)),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    color: AppColors.shortfallMissingText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          GradientButton(
            l10n.commonGotIt,
            icon: Icons.check_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
          if (onEarnPoints != null) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: onEarnPoints,
              icon: const Icon(LucideIcons.gift, size: 18),
              label: Text(l10n.redeemEarnPoints),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.violet,
                minimumSize: const Size.fromHeight(46),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WalletBadge extends StatelessWidget {
  const _WalletBadge();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 96,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(color: AppColors.shortfallHalo, shape: BoxShape.circle),
        ),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppGradients.emptyIcon,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(color: Color(0x406b4dff), blurRadius: 18, offset: Offset(0, 8)),
            ],
          ),
          child: const Icon(LucideIcons.wallet, color: Colors.white, size: 30),
        ),
        const PositionedDirectional(
          top: 6,
          end: 120,
          child: Icon(Icons.auto_awesome, color: AppColors.star, size: 16),
        ),
        const PositionedDirectional(
          bottom: 10,
          start: 118,
          child: Icon(Icons.auto_awesome, color: AppColors.violet, size: 14),
        ),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.label, required this.points, super.key});

  final IconData icon;
  final String label;
  final int points;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppColors.violet),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 14.5)),
        ),
        Text(
          context.l10n.pointsAmount(Formatters.points(points)),
          textDirection: TextDirection.ltr,
          style: const TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
