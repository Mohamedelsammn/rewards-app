import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/participation.dart';
import '../../../shared/widgets/app_network_image.dart';
import 'bloc/my_giveaways_cubit.dart';
import 'bloc/my_giveaways_state.dart';

/// No mockup was provided for this tab -- derived from the written spec and
/// the app's existing card design language (implementation-plan.md §1.3).
class MyGiveawaysPage extends StatelessWidget {
  const MyGiveawaysPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyGiveawaysCubit(getIt())..load(),
      child: const _MyGiveawaysView(),
    );
  }
}

class _MyGiveawaysView extends StatelessWidget {
  const _MyGiveawaysView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPadding,
              AppSpacing.md,
              AppSpacing.containerPadding,
              0,
            ),
            child: Row(children: [Text(l10n.myGiveawaysTitle, style: AppTypography.headlineMd)]),
          ),
          Expanded(
            child: BlocBuilder<MyGiveawaysCubit, MyGiveawaysState>(
              builder: (context, state) {
                return RefreshIndicator(
                  onRefresh: () => context.read<MyGiveawaysCubit>().load(forceRefresh: true),
                  child: switch (state.status) {
                    MyGiveawaysStatus.loading => const Center(child: CircularProgressIndicator()),
                    MyGiveawaysStatus.error => _ErrorView(
                      onRetry: () => context.read<MyGiveawaysCubit>().load(forceRefresh: true),
                    ),
                    MyGiveawaysStatus.empty => const _EmptyView(),
                    MyGiveawaysStatus.loaded => ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.containerPadding),
                      itemCount: state.participations.length,
                      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) =>
                          _ParticipationTile(participation: state.participations[index]),
                    ),
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipationTile extends StatelessWidget {
  const _ParticipationTile({required this.participation});
  final Participation participation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final giveaway = participation.giveaway;
    final title = giveaway?['title'] as String? ?? l10n.myGiveawaysGiveawayFallback;
    final imageUrl = giveaway?['image_url'] as String?;
    final status = giveaway?['status'] as String?;

    return Container(
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
            width: 64,
            height: 64,
            child: AppNetworkImage(
              url: imageUrl,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  status == 'ended' ? l10n.statusEnded : l10n.statusActive,
                  style: AppTypography.labelSm.copyWith(
                    color: status == 'ended' ? AppColors.outline : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              '#${participation.formattedNumber}',
              style: AppTypography.labelSm.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.card_giftcard_outlined, size: 48, color: AppColors.outline),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.myGiveawaysEmpty, style: AppTypography.bodyMd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.outline),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.myGiveawaysCouldNotLoad, style: AppTypography.bodyMd),
                const SizedBox(height: AppSpacing.md),
                TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
