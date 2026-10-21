import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/giveaway.dart';
import '../../../shared/models/participation.dart';
import '../../../core/theme/app_icons.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../giveaway_details/presentation/giveaway_details_page.dart';
import 'bloc/my_giveaways_cubit.dart';
import 'bloc/my_giveaways_state.dart';

/// Best-effort parse of the embedded giveaway map into a full [Giveaway] so
/// tapping a card can seed GiveawayDetailsCubit and render instantly (see
/// GiveawayDetailsPage.initialGiveaway) -- never lets a malformed/partial
/// embed crash navigation; a null seed just falls back to the cubit's
/// normal cache/network load.
Giveaway? _tryParseGiveaway(Map<String, dynamic>? json) {
  if (json == null) return null;
  try {
    return Giveaway.fromJson(json);
  } catch (_) {
    return null;
  }
}

/// No mockup was provided for this tab -- derived from the written spec and
/// the app's existing card design language (implementation-plan.md §1.3).
class MyGiveawaysPage extends StatelessWidget {
  const MyGiveawaysPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyGiveawaysCubit(getIt(), getIt(), getIt())
        ..load()
        ..subscribeToRealtime(),
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
      bottom: false,
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
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.containerPadding,
                        AppSpacing.containerPadding,
                        AppSpacing.containerPadding,
                        AppSpacing.containerPadding,
                      ),
                      itemCount: state.participations.length,
                      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) =>
                          _MyGiveawayCard(participation: state.participations[index]),
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

/// Noticeably larger than the old compact row (image up top, like the
/// existing Giveaway Analytics/Admin campaign card language) so the card is
/// easier to scan at a glance -- title, organizer, status, and ticket
/// number all get their own breathing room. The USER-only card; the Admin
/// My Giveaways card (`_ActiveCampaignCard` in admin_dashboard_page.dart)
/// is a separate widget and is untouched by this.
class _MyGiveawayCard extends StatelessWidget {
  const _MyGiveawayCard({required this.participation});
  final Participation participation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final giveaway = participation.giveaway;
    final title = giveaway?['title'] as String? ?? l10n.myGiveawaysGiveawayFallback;
    final organizerName = giveaway?['organizer_name'] as String?;
    final imageUrl = giveaway?['image_url'] as String?;
    final status = giveaway?['status'] as String?;
    final isEnded = status == 'ended';
    final isWinner = participation.isWinner;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Material + InkWell (not GestureDetector) so the whole card gets a
      // proper ripple, matching the rest of the app's tappable-card
      // convention (e.g. RoleSelectionPage's _RoleCard).
      child: Material(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              settings: giveawayDetailsSettings(participation.giveawayId),
              builder: (_) => GiveawayDetailsPage(
                giveawayId: participation.giveawayId,
                initialGiveaway: _tryParseGiveaway(participation.giveaway),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: AppNetworkImage(
                      url: imageUrl,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.card),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: AppSpacing.sm,
                    end: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isEnded ? AppColors.outline : AppColors.success,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        isEnded ? l10n.statusEnded : l10n.statusActive,
                        style: AppTypography.labelSm.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (organizerName != null && organizerName.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(AppIcons.verified, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              organizerName,
                              style: AppTypography.labelSm,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      title,
                      style: AppTypography.headlineMd.copyWith(fontSize: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _TicketChip(
                          number: participation.formattedNumber,
                          rewardedFrameUnlocked: participation.rewardedFrameUnlocked,
                        ),
                        const Spacer(),
                        const Icon(AppIcons.next, color: AppColors.outline),
                      ],
                    ),
                    if (isEnded) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _FinishedStateBanner(isWinner: isWinner, l10n: l10n),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketChip extends StatelessWidget {
  const _TicketChip({required this.number, this.rewardedFrameUnlocked = false});
  final String number;
  final bool rewardedFrameUnlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: rewardedFrameUnlocked ? Border.all(color: AppColors.goldAccent, width: 2) : null,
        boxShadow: rewardedFrameUnlocked
            ? [BoxShadow(color: AppColors.goldAccent.withValues(alpha: 0.25), blurRadius: 8)]
            : null,
      ),
      child: Text(
        '#$number',
        style: AppTypography.labelSm.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Mirrors the existing "winner ticket" banner language from Giveaway
/// Analytics (gold container + trophy icon) rather than inventing a new
/// visual treatment, so a finished giveaway's outcome reads consistently
/// across the User and Admin sides of the app.
class _FinishedStateBanner extends StatelessWidget {
  const _FinishedStateBanner({required this.isWinner, required this.l10n});
  final bool isWinner;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isWinner ? AppColors.goldAccent.withValues(alpha: 0.15) : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        children: [
          Icon(
            isWinner ? AppIcons.trophy : AppIcons.info,
            color: isWinner ? Colors.amber : AppColors.outline,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isWinner ? l10n.myGiveawaysWinner : l10n.myGiveawaysNotSelected,
              style: AppTypography.labelSm.copyWith(
                color: isWinner ? AppColors.onSurface : AppColors.outline,
                fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
              ),
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
                const Icon(AppIcons.gift, size: 48, color: AppColors.outline),
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
                const Icon(AppIcons.wifiOff, size: 40, color: AppColors.outline),
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
