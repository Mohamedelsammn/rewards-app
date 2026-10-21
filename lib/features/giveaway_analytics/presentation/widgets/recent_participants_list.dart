import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../bloc/giveaway_analytics_state.dart';

/// The "Recent Participants" section of `GiveawayAnalyticsPage` -- a FIXED,
/// internally-scrollable window (~[visibleRows] rows), never a section that
/// grows with the participant count. Whether there are 50, 1,000, or
/// 100,000 participants, whatever comes after this widget (the "Select
/// Winner" button) stays reachable without scrolling through them all.
class RecentParticipantsList extends StatelessWidget {
  const RecentParticipantsList({super.key, required this.participants, this.visibleRows = 5});

  final List<RecentParticipant> participants;
  final int visibleRows;

  /// The row height, derived from the actual typography/spacing tokens
  /// [_ParticipantRow] renders with (rather than a blind pixel guess) --
  /// stays in sync with those tokens instead of a magic constant.
  static double rowHeight() {
    const avatarDiameter = 36.0; // CircleAvatar radius 18 * 2.
    final nameLineHeight = AppTypography.bodyMd.fontSize! * (AppTypography.bodyMd.height ?? 1);
    final timeLineHeight = AppTypography.labelSm.fontSize! * (AppTypography.labelSm.height ?? 1);
    final rowContentHeight = math.max(avatarDiameter, nameLineHeight + timeLineHeight);
    return rowContentHeight + (AppSpacing.xs * 2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (participants.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(l10n.giveawayAnalyticsNoParticipants, style: AppTypography.bodyMd),
      );
    }
    return SizedBox(
      height: rowHeight() * visibleRows,
      child: ListView.builder(
        itemCount: participants.length,
        itemBuilder: (context, index) => _ParticipantRow(participant: participants[index]),
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.participant});
  final RecentParticipant participant;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.15),
            child: Text(
              participant.fullName.isNotEmpty ? participant.fullName[0].toUpperCase() : '?',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.fullName,
                  style: AppTypography.bodyMd,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(_relativeTime(l10n, participant.createdAt), style: AppTypography.labelSm),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // The 4-digit participation code is the PRIMARY identifier shown
          // here -- never the internal sequence/"Ticket #" ordinal.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              l10n.giveawayAnalyticsParticipationCode(participant.formattedParticipationNumber),
              style: AppTypography.labelSm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(AppLocalizations l10n, DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return l10n.giveawayAnalyticsJustNow;
    if (diff.inMinutes < 60) return l10n.giveawayAnalyticsMinsAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.giveawayAnalyticsHoursAgo(diff.inHours);
    return l10n.giveawayAnalyticsDaysAgo(diff.inDays);
  }
}
