import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/giveaway.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../giveaway_analytics/presentation/giveaway_analytics_page.dart';
import 'bloc/admin_giveaways_cubit.dart';
import 'bloc/admin_giveaways_state.dart';

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

/// Doubles as giveaway management: every campaign the admin has published,
/// with a tap-through into its Analytics (and, from there, winner
/// selection).
class AdminGiveawaysPage extends StatelessWidget {
  const AdminGiveawaysPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminGiveawaysCubit(getIt())..load(),
      child: const _AdminGiveawaysView(),
    );
  }
}

class _AdminGiveawaysView extends StatelessWidget {
  const _AdminGiveawaysView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPadding,
              AppSpacing.md,
              AppSpacing.containerPadding,
              AppSpacing.sm,
            ),
            child: Text(l10n.adminGiveawaysTitle, style: AppTypography.headlineMd),
          ),
          Expanded(
            child: BlocBuilder<AdminGiveawaysCubit, AdminGiveawaysState>(
              builder: (context, state) {
                if (state.status == AdminGiveawaysStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == AdminGiveawaysStatus.error) {
                  return Center(
                    child: TextButton(
                      onPressed: () => context.read<AdminGiveawaysCubit>().load(),
                      child: Text(l10n.commonRetry),
                    ),
                  );
                }
                if (state.giveaways.isEmpty) {
                  return Center(child: Text(l10n.adminGiveawaysEmpty, style: AppTypography.bodyMd));
                }
                return RefreshIndicator(
                  onRefresh: () => context.read<AdminGiveawaysCubit>().load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.containerPadding),
                    itemCount: state.giveaways.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) =>
                        _GiveawayTile(giveaway: state.giveaways[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GiveawayTile extends StatelessWidget {
  const _GiveawayTile({required this.giveaway});
  final Giveaway giveaway;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isActive = giveaway.status == GiveawayStatus.active;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => GiveawayAnalyticsPage(giveawayId: giveaway.id))),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
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
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: AppNetworkImage(
                url: giveaway.imageUrl,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    giveaway.title,
                    style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.adminGiveawaysParticipantsCount(giveaway.participantCount),
                    style: AppTypography.labelSm,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isActive ? AppColors.success : AppColors.outline).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                _statusLabel(l10n, giveaway.status),
                style: AppTypography.labelSm.copyWith(
                  color: isActive ? AppColors.success : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
