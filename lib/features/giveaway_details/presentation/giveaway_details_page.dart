import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/giveaway.dart';
import '../../../shared/models/giveaway_requirement.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/primary_gradient_button.dart';
import '../../participation/presentation/pages/participation_flow_page.dart';
import 'bloc/giveaway_details_cubit.dart';
import 'bloc/giveaway_details_state.dart';

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

class GiveawayDetailsPage extends StatelessWidget {
  const GiveawayDetailsPage({super.key, required this.giveawayId});

  final String giveawayId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GiveawayDetailsCubit(getIt(), getIt())..load(giveawayId),
      child: _GiveawayDetailsView(giveawayId: giveawayId),
    );
  }
}

class _GiveawayDetailsView extends StatelessWidget {
  const _GiveawayDetailsView({required this.giveawayId});

  final String giveawayId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<GiveawayDetailsCubit, GiveawayDetailsState>(
        builder: (context, state) {
          switch (state.status) {
            case GiveawayDetailsStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case GiveawayDetailsStatus.error:
              return _ErrorView(
                onRetry: () =>
                    context.read<GiveawayDetailsCubit>().load(giveawayId, forceRefresh: true),
              );
            case GiveawayDetailsStatus.loaded:
              final giveaway = state.giveaway!;
              return _LoadedView(giveaway: giveaway, state: state);
          }
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPadding,
            AppSpacing.sm,
            AppSpacing.containerPadding,
            AppSpacing.md,
          ),
          child: GiveawayDetailsCta(giveawayId: giveawayId),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 40),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.giveawayDetailsCouldNotLoad, style: AppTypography.bodyMd),
          const SizedBox(height: AppSpacing.md),
          TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.giveaway, required this.state});

  final Giveaway giveaway;
  final GiveawayDetailsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Hero(giveaway: giveaway)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.containerPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(giveaway.title, style: AppTypography.headlineMd),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(giveaway.organizerName, style: AppTypography.bodyMd),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _StatChips(giveaway: giveaway),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.giveawayDetailsAboutPrize,
                  style: AppTypography.headlineMd.copyWith(fontSize: 20),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(giveaway.prizeDescription, style: AppTypography.bodyMd),
                ),
                if (state.requirements.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.giveawayDetailsHowToParticipate,
                    style: AppTypography.headlineMd.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...state.requirements.map((r) => _RequirementTile(requirement: r)),
                ],
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.giveawayDetailsRules,
                  style: AppTypography.headlineMd.copyWith(fontSize: 20),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(giveaway.descriptionRules, style: AppTypography.bodyMd),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.giveaway});
  final Giveaway giveaway;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: AppNetworkImage(
            url: giveaway.imageUrl,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.lg)),
          ),
        ),
        Positioned(
          top: AppSpacing.md,
          left: AppSpacing.md,
          child: _CircleIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.onSurface, size: 20),
        ),
      ),
    );
  }
}

class _StatChips extends StatelessWidget {
  const _StatChips({required this.giveaway});
  final Giveaway giveaway;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final days = giveaway.timeRemaining.inDays;
    final hours = giveaway.timeRemaining.inHours % 24;
    final timeLabel = giveaway.timeRemaining == Duration.zero
        ? l10n.giveawayDetailsEnded
        : days > 0
        ? l10n.giveawayDetailsDaysHoursLeft(days, hours)
        : l10n.giveawayDetailsHoursLeft(hours);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _Chip(
          icon: Icons.people_alt_rounded,
          label: l10n.userHomeJoinedCount(giveaway.participantCount),
        ),
        _Chip(icon: Icons.access_time_rounded, label: timeLabel),
        _Chip(
          icon: Icons.circle,
          iconColor: giveaway.status.name == 'active' ? AppColors.success : AppColors.outline,
          label: _statusLabel(l10n, giveaway.status),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.iconColor});
  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _RequirementTile extends StatelessWidget {
  const _RequirementTile({required this.requirement});
  final GiveawayRequirement requirement;

  IconData get _icon {
    switch (requirement.type) {
      case RequirementType.follow:
        return Icons.camera_alt_outlined;
      case RequirementType.share:
        return Icons.share_outlined;
      case RequirementType.tagFriends:
        return Icons.group_add_outlined;
      case RequirementType.custom:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.15),
            child: Icon(_icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(requirement.label, style: AppTypography.bodyMd)),
          const Icon(Icons.chevron_right_rounded, color: AppColors.outline),
        ],
      ),
    );
  }
}

/// The sticky bottom CTA -- separated so it can read the live cubit state
/// via BlocBuilder without rebuilding the whole scroll view.
class GiveawayDetailsCta extends StatelessWidget {
  const GiveawayDetailsCta({super.key, required this.giveawayId});

  final String giveawayId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GiveawayDetailsCubit, GiveawayDetailsState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        if (state.status != GiveawayDetailsStatus.loaded) return const SizedBox.shrink();
        final giveaway = state.giveaway!;

        if (state.alreadyJoined) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.xl),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  state.myParticipationNumber != null
                      ? l10n.giveawayDetailsYoureInWithNumber(
                          state.myParticipationNumber.toString().padLeft(4, '0'),
                        )
                      : l10n.giveawayDetailsYoureIn,
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }

        return PrimaryGradientButton(
          label: giveaway.isJoinable
              ? l10n.giveawayDetailsGenerateNumber
              : l10n.giveawayDetailsNotActive,
          icon: Icons.card_giftcard_rounded,
          onPressed: giveaway.isJoinable
              ? () async {
                  final result = await Navigator.of(context).push<int>(
                    MaterialPageRoute(builder: (_) => ParticipationFlowPage(giveaway: giveaway)),
                  );
                  if (result != null && context.mounted) {
                    context.read<GiveawayDetailsCubit>().markJoined(result);
                  }
                }
              : null,
        );
      },
    );
  }
}
