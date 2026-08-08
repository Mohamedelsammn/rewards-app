import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../create_giveaway/presentation/create_giveaway_page.dart';
import '../../giveaway_analytics/presentation/giveaway_analytics_page.dart';
import 'bloc/admin_dashboard_cubit.dart';
import 'bloc/admin_dashboard_state.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminDashboardCubit(getIt(), getIt())..load(),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final created = await Navigator.of(
            context,
          ).push<bool>(MaterialPageRoute(builder: (_) => const CreateGiveawayPage()));
          if (created == true && context.mounted) {
            context.read<AdminDashboardCubit>().load();
          }
        },
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
          builder: (context, state) {
            if (state.status == AdminDashboardStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == AdminDashboardStatus.error) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.adminDashboardCouldNotLoad, style: AppTypography.bodyMd),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () => context.read<AdminDashboardCubit>().load(),
                      child: Text(l10n.commonRetry),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => context.read<AdminDashboardCubit>().load(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.containerPadding),
                children: [
                  Text(
                    l10n.adminDashboardGoodDay,
                    style: AppTypography.headlineLg.copyWith(fontSize: 26),
                  ),
                  Text(l10n.adminDashboardAdministrator, style: AppTypography.bodyMd),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.campaign_rounded,
                          label: l10n.adminDashboardActiveGiveaways,
                          value: '${state.activeCount}',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.people_alt_rounded,
                          label: l10n.adminDashboardTotalParticipants,
                          value: '${state.totalParticipants}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.check_circle_rounded,
                          label: l10n.adminDashboardFinished,
                          value: '${state.finishedCount}',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.emoji_events_rounded,
                          label: l10n.adminDashboardWinnersSelected,
                          value: '${state.winnersSelectedCount}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (state.activeCampaign != null) ...[
                    Text(
                      l10n.adminDashboardActiveCampaign,
                      style: AppTypography.headlineMd.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ActiveCampaignCard(
                      giveawayId: state.activeCampaign!.id,
                      title: state.activeCampaign!.title,
                      organizerName: state.activeCampaign!.organizerName,
                      imageUrl: state.activeCampaign!.imageUrl,
                      participantCount: state.activeCampaign!.participantCount,
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(
                        child: Text(
                          l10n.adminDashboardNoActiveCampaigns,
                          style: AppTypography.bodyMd,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
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

class _ActiveCampaignCard extends StatelessWidget {
  const _ActiveCampaignCard({
    required this.giveawayId,
    required this.title,
    required this.organizerName,
    required this.imageUrl,
    required this.participantCount,
  });

  final String giveawayId;
  final String title;
  final String organizerName;
  final String? imageUrl;
  final int participantCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
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
          AspectRatio(
            aspectRatio: 16 / 9,
            child: AppNetworkImage(
              url: imageUrl,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(organizerName.toUpperCase(), style: AppTypography.labelSm),
                Text(title, style: AppTypography.headlineMd.copyWith(fontSize: 18)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.adminDashboardParticipantsCount(participantCount),
                  style: AppTypography.bodyMd,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GiveawayAnalyticsPage(giveawayId: giveawayId),
                      ),
                    ),
                    child: Text(l10n.adminDashboardViewAnalytics),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
