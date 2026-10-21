import 'package:flutter/material.dart';
import '../../../core/theme/app_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/participation_growth_chart.dart';
import 'bloc/admin_analysis_cubit.dart';
import 'bloc/admin_analysis_state.dart';

class AdminAnalysisPage extends StatelessWidget {
  const AdminAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminAnalysisCubit(getIt(), getIt(), getIt())
        ..load()
        ..subscribeToRealtime(),
      child: const _AdminAnalysisView(),
    );
  }
}

class _AdminAnalysisView extends StatelessWidget {
  const _AdminAnalysisView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: BlocBuilder<AdminAnalysisCubit, AdminAnalysisState>(
        builder: (context, state) {
          if (state.status == AdminAnalysisStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == AdminAnalysisStatus.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.adminAnalysisCouldNotLoad, style: AppTypography.bodyMd),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => context.read<AdminAnalysisCubit>().load(),
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            );
          }
          if (state.status == AdminAnalysisStatus.empty) {
            return RefreshIndicator(
              onRefresh: () => context.read<AdminAnalysisCubit>().load(),
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(AppIcons.chart, size: 48, color: AppColors.outline),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              l10n.adminAnalysisNoData,
                              style: AppTypography.bodyMd,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<AdminAnalysisCubit>().load(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.containerPadding,
                AppSpacing.containerPadding,
                AppSpacing.containerPadding,
                // Actual nav footprint (not a fixed guess) plus a small
                // comfortable gap so the chart is never hidden behind the
                // floating liquid-glass bottom nav on any screen size.
                AppBottomNav.footprint(context) + AppSpacing.md,
              ),
              children: [
                Text(
                  l10n.adminAnalysisTitle,
                  style: AppTypography.headlineLg.copyWith(fontSize: 26),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: AppIcons.campaign,
                        label: l10n.adminAnalysisTotalGiveaways,
                        value: '${state.totalGiveaways}',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _StatCard(
                        icon: AppIcons.play,
                        label: l10n.adminAnalysisActiveGiveaways,
                        value: '${state.activeCount}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: AppIcons.checkCircle,
                        label: l10n.adminAnalysisFinishedGiveaways,
                        value: '${state.finishedCount}',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _StatCard(
                        icon: AppIcons.participants,
                        label: l10n.adminAnalysisTotalParticipants,
                        value: '${state.totalParticipants}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _StatCard(
                  icon: AppIcons.trophy,
                  label: l10n.adminAnalysisTotalWinners,
                  value: '${state.totalWinners}',
                  fullWidth: true,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.adminAnalysisGrowthTrend,
                  style: AppTypography.headlineMd.copyWith(fontSize: 18),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 200,
                  child: ParticipationGrowthChart(
                    dailyGrowth: state.dailyGrowth,
                    emptyMessage: l10n.giveawayAnalyticsNoParticipants,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(AppSpacing.md),
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
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: AppTypography.labelSm),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.headlineMd.copyWith(fontSize: 22)),
        ],
      ),
    );
  }
}
