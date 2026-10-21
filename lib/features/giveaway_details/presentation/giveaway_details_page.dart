import 'package:flutter/material.dart';
import '../../../core/theme/app_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/giveaway.dart';
import '../../../shared/models/giveaway_requirement.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/hero_back_button.dart';
import '../../../shared/widgets/primary_gradient_button.dart';
import '../../participation/presentation/pages/participation_flow_page.dart';
import 'bloc/giveaway_details_cubit.dart';
import 'bloc/giveaway_details_state.dart';
import 'package:intl/intl.dart';

RouteSettings giveawayDetailsSettings(String id) => RouteSettings(name: '/giveaway/$id');

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
  const GiveawayDetailsPage({super.key, required this.giveawayId, this.initialGiveaway});

  final String giveawayId;

  /// When the caller already has this giveaway's data in memory (e.g.
  /// tapping a card on Home or My Giveaways), passing it here renders the
  /// page instantly with no loading state -- the cubit still refreshes it
  /// silently in the background.
  final Giveaway? initialGiveaway;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GiveawayDetailsCubit(getIt(), getIt(), getIt(), seed: initialGiveaway)
        ..load(giveawayId)
        ..subscribeToRealtime(giveawayId),
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
          const Icon(AppIcons.error, color: AppColors.error, size: 40),
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
                    const Icon(AppIcons.verified, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        giveaway.organizerName,
                        style: AppTypography.bodyMd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _StatChips(giveaway: giveaway),
                // Prize description and rules are optional at creation --
                // Giveaway Details hides each section entirely when left
                // blank rather than showing an empty box or the literal
                // word "null". Giveaways created before this change (which
                // always had both filled in) render exactly as before.
                if (giveaway.prizeDescription.trim().isNotEmpty) ...[
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
                ],
                if (state.requirements.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.giveawayDetailsHowToParticipate,
                    style: AppTypography.headlineMd.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...state.requirements.map((r) => _RequirementTile(requirement: r)),
                ],
                if (giveaway.descriptionRules.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.giveawayDetailsRules,
                    style: AppTypography.headlineMd.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(giveaway.descriptionRules, style: AppTypography.bodyMd),
                ],
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
        SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // A taller, square-ish canvas gives portrait products room to
              // render fully while staying proportional to the available
              // phone width. The image itself is never cropped or stretched.
              final imageHeight = (constraints.maxWidth * 0.92).clamp(280.0, 460.0);
              return SizedBox(
                width: double.infinity,
                height: imageHeight,
                child: ColoredBox(
                  color: AppColors.surface,
                  child: AppNetworkImage(
                    url: giveaway.imageUrl,
                    fit: BoxFit.contain,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppSpacing.lg),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // SafeArea-aware -- see HeroBackButton's doc comment for the bug
        // this replaced (a fixed offset that ignored the device's actual
        // status-bar/notch height).
        const HeroBackButton(),
      ],
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
          icon: AppIcons.participants,
          label: l10n.userHomeJoinedCount(giveaway.participantCount),
        ),
        _Chip(icon: AppIcons.clock, label: timeLabel),
        _Chip(
          icon: AppIcons.dot,
          iconColor: giveaway.status.name == 'active' ? AppColors.success : AppColors.outline,
          label: _statusLabel(l10n, giveaway.effectiveStatus),
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
        return AppIcons.camera;
      case RequirementType.share:
        return AppIcons.share;
      case RequirementType.tagFriends:
        return AppIcons.userPlus;
      case RequirementType.custom:
        return AppIcons.checkCircle;
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
          // No trailing chevron here (final correction pass): these tiles
          // are informational -- they don't navigate anywhere on tap, so an
          // arrow implying "go to a next screen" was misleading. Content
          // stays left-aligned via the Expanded label; removing the arrow
          // doesn't leave a gap since nothing else needs that trailing space.
          Expanded(child: Text(requirement.label, style: AppTypography.bodyMd)),
        ],
      ),
    );
  }
}

/// The sticky bottom CTA -- separated so it can read the live cubit state
/// via BlocBuilder without rebuilding the whole scroll view.
class GiveawayDetailsCta extends StatefulWidget {
  const GiveawayDetailsCta({super.key, required this.giveawayId});

  final String giveawayId;

  @override
  State<GiveawayDetailsCta> createState() => _GiveawayDetailsCtaState();
}

class _GiveawayDetailsCtaState extends State<GiveawayDetailsCta> {
  bool _openingParticipation = false;

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
              border: state.rewardedFrameUnlocked
                  ? Border.all(color: AppColors.goldAccent, width: 2)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(AppIcons.checkCircle, color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    state.myParticipationNumber != null
                        ? l10n.giveawayDetailsYoureInWithNumber(
                            state.myParticipationNumber.toString().padLeft(4, '0'),
                          )
                        : l10n.giveawayDetailsYoureIn,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyLg.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (state.participationCheckStatus == ParticipationCheckStatus.loading ||
            state.participationCheckStatus == ParticipationCheckStatus.initial) {
          return Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.xl),
            ),
            child: const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (state.participationCheckStatus == ParticipationCheckStatus.error) {
          return TextButton.icon(
            onPressed: () =>
                context.read<GiveawayDetailsCubit>().load(widget.giveawayId, forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.commonRetry),
          );
        }

        return PrimaryGradientButton(
          label: giveaway.isJoinable
              ? l10n.giveawayDetailsGenerateNumber
              : giveaway.effectiveStatus == GiveawayStatus.scheduled
              ? l10n.browseUpcomingMessage(
                  DateFormat.yMMMd(
                    Localizations.localeOf(context).languageCode,
                  ).add_Hm().format(giveaway.startsAt),
                )
              : l10n.giveawayDetailsNotActive,
          icon: AppIcons.gift,
          onPressed: giveaway.isJoinable && !_openingParticipation
              ? () async {
                  setState(() => _openingParticipation = true);
                  try {
                    final result = await Navigator.of(context).push<int>(
                      MaterialPageRoute(builder: (_) => ParticipationFlowPage(giveaway: giveaway)),
                    );
                    if (result != null && context.mounted) {
                      context.read<GiveawayDetailsCubit>().markJoined(result);
                    }
                  } finally {
                    if (mounted) setState(() => _openingParticipation = false);
                  }
                }
              : null,
          isLoading: _openingParticipation,
        );
      },
    );
  }
}
