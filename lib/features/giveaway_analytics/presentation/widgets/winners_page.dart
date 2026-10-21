import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/models/winner.dart';

String _formatSelectedAt(DateTime selectedAt) {
  final local = selectedAt.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '${local.month}/${local.day}/${local.year} · $hh:$mm';
}

/// Dedicated Winners view for a single giveaway, reached from Analytics'
/// "View Winners" entry point. [winners] is the already-loaded list from
/// [GiveawayAnalyticsCubit]'s state (itself sourced from
/// [WinnerRepository.getWinnersForGiveaway]) -- this page fetches nothing
/// of its own and owns no winner data; it is purely a presentation layer.
///
/// Swiping a card away only removes it from THIS page's local, in-memory
/// list ([_hiddenIds]) -- never a database call, never touching the
/// underlying `winners` rows, rank, or any other record. Nothing is
/// persisted: closing and reopening this page (a fresh [winners] list)
/// shows every winner again, exactly as the requirement asks ("prefer
/// keeping the underlying database data untouched... do not invent
/// persistent 'deleted winner' state").
class WinnersPage extends StatefulWidget {
  const WinnersPage({super.key, required this.winners});

  final List<Winner> winners;

  @override
  State<WinnersPage> createState() => _WinnersPageState();
}

class _WinnersPageState extends State<WinnersPage> {
  final Set<String> _hiddenIds = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visibleWinners = widget.winners.where((w) => !_hiddenIds.contains(w.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l10n.giveawayAnalyticsWinnersSectionTitle)),
      body: visibleWinners.isEmpty
          ? Center(child: Text(l10n.giveawayAnalyticsNoWinners, style: AppTypography.bodyMd))
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.containerPadding),
              itemCount: visibleWinners.length,
              itemBuilder: (context, index) {
                final winner = visibleWinners[index];
                return Dismissible(
                  key: ValueKey(winner.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => setState(() => _hiddenIds.add(winner.id)),
                  background: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    alignment: AlignmentDirectional.centerEnd,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Icon(
                      Icons.visibility_off_rounded,
                      color: Colors.white,
                      semanticLabel: l10n.giveawayAnalyticsRemoveFromView,
                    ),
                  ),
                  child: _WinnerCard(winner: winner),
                );
              },
            ),
    );
  }
}

/// The premium winner card: badge, the 4-digit participation code (the
/// primary identifier, large and prominent), participant name/phone, and
/// the selection timestamp.
class _WinnerCard extends StatelessWidget {
  const _WinnerCard({required this.winner});
  final Winner winner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.gradientGold,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldAccent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                winner.rank <= 1
                    ? l10n.giveawayAnalyticsWinnerLabel.toUpperCase()
                    : l10n.giveawayAnalyticsWinnerRank(winner.rank).toUpperCase(),
                style: AppTypography.labelSm.copyWith(color: Colors.white, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            winner.formattedParticipationNumber,
            style: AppTypography.display.copyWith(
              color: Colors.white,
              fontSize: 40,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (winner.fullName != null && winner.fullName!.isNotEmpty)
            Text(
              winner.fullName!,
              style: AppTypography.bodyLg.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (winner.phoneE164 != null && winner.phoneE164!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              winner.phoneE164!,
              style: AppTypography.bodyMd.copyWith(color: Colors.white.withValues(alpha: 0.85)),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '${l10n.giveawayAnalyticsSelectedAtLabel}: ${_formatSelectedAt(winner.selectedAt)}',
            style: AppTypography.labelSm.copyWith(color: Colors.white.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}
