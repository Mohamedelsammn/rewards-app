import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/giveaway.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/primary_gradient_button.dart';
import 'bloc/giveaway_analytics_cubit.dart';
import 'bloc/giveaway_analytics_state.dart';

String _statusLabel(AppLocalizations l10n, GiveawayStatus status) {
  switch (status) {
    case GiveawayStatus.active:
      return l10n.statusActive;
    case GiveawayStatus.ended:
      return l10n.statusEnded;
    case GiveawayStatus.draft:
      return l10n.statusDraft;
    case GiveawayStatus.scheduled:
      return l10n.statusScheduled;
    case GiveawayStatus.archived:
      return l10n.statusArchived;
    case GiveawayStatus.unknown:
      return status.name;
  }
}

class GiveawayAnalyticsPage extends StatelessWidget {
  const GiveawayAnalyticsPage({super.key, required this.giveawayId});

  final String giveawayId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GiveawayAnalyticsCubit(getIt(), getIt(), getIt())..load(giveawayId),
      child: _GiveawayAnalyticsView(giveawayId: giveawayId),
    );
  }
}

class _GiveawayAnalyticsView extends StatelessWidget {
  const _GiveawayAnalyticsView({required this.giveawayId});
  final String giveawayId;

  Future<void> _confirmSelectWinner(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<GiveawayAnalyticsCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.giveawayAnalyticsSelectWinnerTitle),
        content: Text(l10n.giveawayAnalyticsSelectWinnerBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.giveawayAnalyticsSelectWinnerAction),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await cubit.selectWinner(giveawayId);
    if (!context.mounted) return;

    final errorMessage = cubit.state.failure?.localize(l10n);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage ?? l10n.giveawayAnalyticsWinnerSelected),
        backgroundColor: errorMessage != null ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l10n.giveawayAnalyticsTitle)),
      body: BlocBuilder<GiveawayAnalyticsCubit, GiveawayAnalyticsState>(
        builder: (context, state) {
          if (state.status == GiveawayAnalyticsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == GiveawayAnalyticsStatus.error || state.giveaway == null) {
            return Center(
              child: TextButton(
                onPressed: () => context.read<GiveawayAnalyticsCubit>().load(giveawayId),
                child: Text(l10n.commonRetry),
              ),
            );
          }

          final giveaway = state.giveaway!;
          final hasWinner = state.winners.isNotEmpty;

          return RefreshIndicator(
            onRefresh: () => context.read<GiveawayAnalyticsCubit>().load(giveawayId),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.containerPadding),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: AppNetworkImage(
                              url: giveaway.imageUrl,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppRadius.card),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: giveaway.isJoinable ? AppColors.success : AppColors.outline,
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                _statusLabel(l10n, giveaway.status),
                                style: AppTypography.labelSm.copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          giveaway.title,
                          style: AppTypography.headlineMd.copyWith(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: l10n.giveawayAnalyticsTotalJoined,
                        value: '${giveaway.participantCount}',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _StatTile(
                        label: l10n.giveawayAnalyticsActiveToday,
                        value: '${state.activeToday}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.giveawayAnalyticsParticipationGrowth,
                  style: AppTypography.headlineMd.copyWith(fontSize: 18),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(height: 160, child: _GrowthChart(dailyGrowth: state.dailyGrowth)),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.giveawayAnalyticsRecentParticipants,
                      style: AppTypography.headlineMd.copyWith(fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (state.recentParticipants.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text(l10n.giveawayAnalyticsNoParticipants, style: AppTypography.bodyMd),
                  )
                else
                  ...state.recentParticipants.map((p) => _ParticipantRow(participant: p)),
                const SizedBox(height: AppSpacing.xl),
                if (hasWinner)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: Colors.amber),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            l10n.giveawayAnalyticsWinnerTicket(
                              state.winners.first.participationNumber?.toString() ?? '----',
                            ),
                            style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  PrimaryGradientButton(
                    label: l10n.giveawayAnalyticsSelectWinnerAction,
                    icon: Icons.emoji_events_rounded,
                    gradient: AppColors.gradientGold,
                    isLoading: state.isSelectingWinner,
                    onPressed: state.isSelectingWinner || giveaway.participantCount == 0
                        ? null
                        : () => _confirmSelectWinner(context),
                  ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSm),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.headlineMd.copyWith(fontSize: 22)),
        ],
      ),
    );
  }
}

class _GrowthChart extends StatelessWidget {
  const _GrowthChart({required this.dailyGrowth});
  final List<int> dailyGrowth;

  @override
  Widget build(BuildContext context) {
    final maxY = (dailyGrowth.isEmpty ? 1 : dailyGrowth.reduce((a, b) => a > b ? a : b)).toDouble();
    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 1 : maxY * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: [
          for (var i = 0; i < dailyGrowth.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: dailyGrowth[i].toDouble(),
                  color: AppColors.primary,
                  width: 22,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
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
                Text(participant.fullName, style: AppTypography.bodyMd),
                Text(_relativeTime(l10n, participant.createdAt), style: AppTypography.labelSm),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              l10n.giveawayAnalyticsTicketNumber(participant.participationSequence),
              style: AppTypography.labelSm,
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
