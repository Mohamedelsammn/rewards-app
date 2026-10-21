import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/error/result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/eligible_participant.dart';
import '../../../shared/models/giveaway.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/participation_growth_chart.dart';
import '../../../shared/widgets/primary_gradient_button.dart';
import 'bloc/giveaway_analytics_cubit.dart';
import 'bloc/giveaway_analytics_state.dart';
import 'widgets/recent_participants_list.dart';
import 'widgets/view_winners_button.dart';
import 'widgets/winner_wheel_overlay.dart';
import 'widgets/winners_page.dart';
import '../../create_giveaway/presentation/create_giveaway_page.dart';

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
      create: (_) => GiveawayAnalyticsCubit(getIt(), getIt(), getIt(), getIt())
        ..load(giveawayId)
        ..subscribeToRealtime(giveawayId),
      child: _GiveawayAnalyticsView(giveawayId: giveawayId),
    );
  }
}

class _GiveawayAnalyticsView extends StatefulWidget {
  const _GiveawayAnalyticsView({required this.giveawayId});
  final String giveawayId;

  @override
  State<_GiveawayAnalyticsView> createState() => _GiveawayAnalyticsViewState();
}

class _GiveawayAnalyticsViewState extends State<_GiveawayAnalyticsView> {
  // Whether the wheel overlay is currently showing on top of this page. The
  // decoy pool/manual target are snapshotted at press-time (mirroring what
  // used to be passed as route arguments) so they stay stable for the
  // overlay's lifetime even if the underlying cubit state changes meanwhile.
  bool _showWheel = false;
  List<RecentParticipant> _wheelDecoyPool = const [];
  EligibleParticipant? _wheelManualTarget;

  /// Opens the eligible-participant picker from the top app bar. Choosing a
  /// row here only marks that participant as the pending manual target
  /// ([GiveawayAnalyticsCubit.setManualTarget]) -- it never selects a
  /// winner by itself. The actual selection only happens once the admin
  /// presses "Select Winner"/"Select Another Winner" below.
  Future<void> _openParticipantPicker(BuildContext context) async {
    final cubit = context.read<GiveawayAnalyticsCubit>();
    // Fetched from the OUTER context (which has the page's BlocProvider as
    // an ancestor) and handed to the sheet as a plain value -- a bottom
    // sheet is pushed as its own route, so its own builder context sits
    // outside this page's BlocProvider and can't safely `context.read` it.
    final eligibleFuture = cubit.fetchEligibleParticipants(widget.giveawayId);
    final chosen = await showModalBottomSheet<EligibleParticipant>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ParticipantPickerSheet(future: eligibleFuture),
    );

    if (chosen == null || !context.mounted) return;
    cubit.setManualTarget(chosen);
  }

  /// Shows the wheel-of-fortune reveal as an overlay on top of this page
  /// (never a pushed route), which itself calls
  /// [GiveawayAnalyticsCubit.selectWinner] -- with the pending manual
  /// target's participation id if one was chosen from the picker, or none
  /// at all for the normal random path. `decoyPool` is the page's own
  /// already-loaded Recent Participants list -- never a fresh fetch just to
  /// populate the wheel. Both are snapshotted now so the overlay stays
  /// stable even if a realtime reload changes `state` while it's open.
  void _handleSelectWinnerPressed(BuildContext context, GiveawayAnalyticsState state) {
    setState(() {
      _wheelDecoyPool = state.recentParticipants;
      _wheelManualTarget = state.manualTarget;
      _showWheel = true;
    });
  }

  void _closeWheel() => setState(() => _showWheel = false);

  /// Admin-only TRUE hard delete (Phase 1): confirms with the admin first
  /// (explicit, permanent-action warning -- mirrors Settings' Sign Out
  /// confirmation pattern), then calls [GiveawayAnalyticsCubit.deleteGiveaway],
  /// which routes through the atomic, server-authorized
  /// `fn_admin_delete_giveaway` RPC. On success, pops back to wherever this
  /// page was opened from -- Admin Dashboard picks the removal up on its
  /// own via its existing Realtime subscription to `giveaways`, the same
  /// as any other giveaway change.
  Future<void> _confirmAndDeleteGiveaway(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<GiveawayAnalyticsCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.giveawayAnalyticsDeleteGiveawayTitle),
        content: Text(l10n.giveawayAnalyticsDeleteGiveawayBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonDelete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final succeeded = await cubit.deleteGiveaway(widget.giveawayId);
    if (!context.mounted) return;

    if (succeeded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.giveawayAnalyticsGiveawayDeleted)));
      Navigator.of(context).pop();
    } else {
      final failure = cubit.state.failure;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure?.localize(l10n) ?? l10n.failureServer)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<GiveawayAnalyticsCubit>();
    return PopScope(
      // While the wheel overlay is up, back/system-pop must never navigate
      // away from Analytics out from under it -- the overlay's own Done/
      // Dismiss actions (or, for a mid-spin state, nothing at all) are the
      // only way out, mirroring the guard the old pushed route had.
      canPop: !_showWheel,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text(l10n.giveawayAnalyticsTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.categoryEditGiveaway,
              onPressed: () async {
                final cubit = context.read<GiveawayAnalyticsCubit>();
                final giveaway = cubit.state.giveaway;
                if (giveaway == null || giveaway.effectiveStatus == GiveawayStatus.ended) return;
                await Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => CreateGiveawayPage(giveaway: giveaway)));
                if (context.mounted) await cubit.load(widget.giveawayId);
              },
            ),
            // Subtle by design (Phase 2): deliberately not an icon that reads
            // as "winner"/"person"/"select user" -- opens the manual
            // participant picker, which only ever sets a PENDING target (see
            // _openParticipantPicker); it never selects a winner by itself.
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: l10n.giveawayAnalyticsChooseParticipantTooltip,
              onPressed: () => _openParticipantPicker(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: l10n.giveawayAnalyticsDeleteGiveawayTooltip,
              onPressed: () => _confirmAndDeleteGiveaway(context),
            ),
          ],
        ),
        body: Stack(
          children: [
            BlocBuilder<GiveawayAnalyticsCubit, GiveawayAnalyticsState>(
              builder: (context, state) {
                if (state.status == GiveawayAnalyticsStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == GiveawayAnalyticsStatus.error || state.giveaway == null) {
                  return Center(
                    child: TextButton(
                      onPressed: () =>
                          context.read<GiveawayAnalyticsCubit>().load(widget.giveawayId),
                      child: Text(l10n.commonRetry),
                    ),
                  );
                }

                final giveaway = state.giveaway!;
                final hasWinner = state.winners.isNotEmpty;
                // Every current participant has already won -- nothing left
                // to pick from (mirrors the server's own no_eligible_
                // participants check, just surfaced proactively in the UI).
                final noneEligibleLeft =
                    giveaway.participantCount > 0 &&
                    state.winners.length >= giveaway.participantCount;

                return RefreshIndicator(
                  onRefresh: () => context.read<GiveawayAnalyticsCubit>().load(widget.giveawayId),
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
                                PositionedDirectional(
                                  end: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: giveaway.isJoinable
                                          ? AppColors.success
                                          : AppColors.outline,
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
                      // Winner entry point: right below the hero image, above
                      // the stat tiles, so it keeps the strongest visual
                      // hierarchy on the page -- full winner cards themselves
                      // now live on the dedicated WinnersPage instead of being
                      // inlined here.
                      if (hasWinner) ...[
                        const SizedBox(height: AppSpacing.xl),
                        ViewWinnersButton(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => WinnersPage(winners: state.winners)),
                          ),
                        ),
                      ],
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
                      SizedBox(
                        height: 200,
                        child: ParticipationGrowthChart(
                          dailyGrowth: state.dailyGrowth,
                          emptyMessage: l10n.giveawayAnalyticsNoParticipants,
                        ),
                      ),
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
                      RecentParticipantsList(participants: state.recentParticipants),
                      const SizedBox(height: AppSpacing.xl),
                      PrimaryGradientButton(
                        label: hasWinner
                            ? l10n.giveawayAnalyticsSelectAnotherWinnerAction
                            : l10n.giveawayAnalyticsSelectWinnerAction,
                        icon: Icons.emoji_events_rounded,
                        gradient: AppColors.gradientGold,
                        isLoading: state.isSelectingWinner,
                        onPressed:
                            state.isSelectingWinner ||
                                giveaway.participantCount == 0 ||
                                noneEligibleLeft
                            ? null
                            : () => _handleSelectWinnerPressed(context, state),
                      ),
                      if (noneEligibleLeft) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.giveawayAnalyticsNoEligibleParticipants,
                          style: AppTypography.labelSm,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                );
              },
            ),
            // Winner-selection overlay: presented on top of this same page
            // (never a pushed route) so the Analytics content stays visible
            // -- just blurred -- behind it. See WinnerWheelOverlay for the
            // random/manual selection + spin/reveal orchestration, which is
            // unchanged from the previous pushed-route version.
            if (_showWheel) ...[
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(color: AppColors.inverseSurface.withValues(alpha: 0.72)),
                ),
              ),
              Positioned.fill(
                child: WinnerWheelOverlay(
                  cubit: cubit,
                  giveawayId: widget.giveawayId,
                  decoyPool: _wheelDecoyPool,
                  manualTarget: _wheelManualTarget,
                  onClose: _closeWheel,
                ),
              ),
            ],
          ],
        ),
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

/// The manual "Select Winner" participant picker (Phase 3/4): every
/// eligible participant (never capped, never already a winner), with the
/// four-digit participation code as the PRIMARY identifier -- never "Ticket
/// #1". Tapping a row returns that exact participant to the caller
/// immediately -- this only marks them as the PENDING manual target (see
/// [GiveawayAnalyticsCubit.setManualTarget]); it never selects a winner by
/// itself, so no confirmation step is needed here.
class _ParticipantPickerSheet extends StatelessWidget {
  const _ParticipantPickerSheet({required this.future});

  final Future<Result<List<EligibleParticipant>>> future;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        // A Material (not a colored DecoratedBox/Container) so it becomes
        // the ListTiles' nearest Material ancestor -- a colored DecoratedBox
        // between a ListTile and its Material paints over the ink splash
        // effects, which Flutter flags as an error in debug/test builds.
        return Material(
          color: AppColors.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l10n.giveawayAnalyticsSelectParticipantTitle,
                    style: AppTypography.headlineMd.copyWith(fontSize: 18),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<Result<List<EligibleParticipant>>>(
                    future: future,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return snapshot.data!.fold(
                        (failure) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Text(failure.localize(l10n), textAlign: TextAlign.center),
                          ),
                        ),
                        (participants) {
                          if (participants.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Text(
                                  l10n.giveawayAnalyticsNoEligibleParticipants,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            itemCount: participants.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1, color: AppColors.outlineVariant),
                            itemBuilder: (context, index) {
                              final participant = participants[index];
                              return ListTile(
                                onTap: () => Navigator.of(context).pop(participant),
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(AppRadius.chip),
                                  ),
                                  child: Text(
                                    participant.formattedNumber,
                                    style: AppTypography.bodyLg.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  participant.fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: participant.phoneE164 != null
                                    ? Text(
                                        participant.phoneE164!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : null,
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.outline,
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
