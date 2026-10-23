import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/giveaway_entities.dart';
import '../bloc/giveaway_cubits.dart';
import '../join_ad/giveaway_join_ads.dart';
import '../widgets/giveaway_detail_sections.dart';
import '../widgets/giveaway_details_skeleton.dart';
import '../widgets/giveaway_join_button.dart';
import '../widgets/giveaway_steps.dart';
import 'ticket_page.dart';

class GiveawayDetailsPage extends StatelessWidget {
  const GiveawayDetailsPage({required this.giveawayId, super.key});

  final String giveawayId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => GiveawayDetailsCubit(sl(), giveawayId)..load(),
    child: const _GiveawayDetailsView(),
  );
}

class _GiveawayDetailsView extends StatefulWidget {
  const _GiveawayDetailsView();

  @override
  State<_GiveawayDetailsView> createState() => _GiveawayDetailsViewState();
}

class _GiveawayDetailsViewState extends State<_GiveawayDetailsView> {
  /// A join (with its optional ad) is in progress; further taps are ignored.
  bool _joining = false;

  Future<void> _join(Giveaway giveaway) async {
    if (_joining) return;
    _joining = true;
    try {
      await _joinOnce(giveaway);
    } finally {
      _joining = false;
    }
  }

  Future<void> _joinOnce(Giveaway giveaway) async {
    final cubit = context.read<GiveawayDetailsCubit>();
    // Ad-gated joining: explicit consent, then the ad's reward callback; the
    // existing entry API still creates the entry and its number.
    final ads = sl.isRegistered<GiveawayJoinAds>() ? sl<GiveawayJoinAds>() : null;
    if (ads != null && ads.requiresAd(giveaway)) {
      final l10n = context.l10n;
      final consent = await showAppConfirmDialog(
        context,
        icon: Icons.play_circle_outline_rounded,
        title: l10n.joinAdTitle,
        message: l10n.joinAdBody,
        confirmLabel: l10n.joinAdWatch,
      );
      if (!consent || !mounted) return;
      final outcome = await ads.watch(giveaway);
      if (!mounted) return;
      if (outcome != JoinAdOutcome.rewardEarned) {
        if (_joinAdMessage(context, outcome) case final message?) showAppSnackBar(context, message);
        return;
      }
    }
    final entry = await cubit.enter();
    if (!mounted) return;
    if (entry == null) {
      if (cubit.state.error != null) showErrorSnackBar(context, cubit.state.error!);
      return;
    }
    await context.push(
      Routes.ticket,
      extra: TicketArgs(title: giveaway.title.of(context), number: entry.participationNumber),
    );
  }

  String? _joinAdMessage(BuildContext context, JoinAdOutcome outcome) {
    final l10n = context.l10n;
    return switch (outcome) {
      JoinAdOutcome.rewardEarned => null,
      JoinAdOutcome.skipped => l10n.joinAdSkipped,
      JoinAdOutcome.unavailable => l10n.earnAdFailed,
      JoinAdOutcome.failed => l10n.joinAdFailed,
    };
  }

  @override
  // The hero runs behind a transparent status bar; dark icons stay readable
  // on the light artwork and on the white panel once scrolled.
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
    child: Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<GiveawayDetailsCubit, GiveawayDetailsState>(
        builder: (context, state) {
          final details = state.details;
          final Widget content;
          if (details != null) {
            content = _content(context, state, details);
          } else if (state.status == GiveawayDetailsStatus.failed) {
            content = SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
                child: ErrorStateView(
                  error: state.error!,
                  onRetry: context.read<GiveawayDetailsCubit>().load,
                ),
              ),
            );
          } else {
            content = const GiveawayDetailsSkeleton();
          }
          return Stack(
            children: [
              Positioned.fill(child: content),
              const Positioned(top: 0, left: 0, right: 0, child: _TopBar()),
              if (details != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _JoinBar(child: _cta(context, state, details)),
                ),
            ],
          );
        },
      ),
    ),
  );

  Widget _content(BuildContext context, GiveawayDetailsState state, GiveawayDetails details) {
    final l10n = context.l10n;
    final giveaway = details.giveaway;
    final media = MediaQuery.of(context);
    final heroHeight = giveawayHeroHeight(media.size.width);
    final description = giveaway.description.of(context);
    final rules = giveaway.rules.of(context);
    final canAct = giveaway.isActive && details.entry == null;
    // Room so the last card is never hidden behind the fixed button.
    final bottomSpace = GiveawayJoinButton.height + 36 + media.padding.bottom;
    return RefreshIndicator(
      onRefresh: context.read<GiveawayDetailsCubit>().load,
      edgeOffset: media.padding.top + 56,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Stack(
          children: [
            GiveawayHero(giveaway: giveaway, height: heroHeight),
            Padding(
              padding: EdgeInsets.only(top: heroHeight - giveawayPanelOverlap),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: media.size.height - heroHeight + giveawayPanelOverlap,
                ),
                child: GiveawayPanel(
                  children: [
                    GiveawayHeadline(giveaway: giveaway),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      GiveawayAboutCard(text: description),
                    ],
                    // The Prize card of the reference is intentionally omitted.
                    if (rules.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      GiveawayRulesCard(text: rules),
                    ],
                    if (giveaway.steps.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      GiveawayInfoCard(
                        icon: LucideIcons.listChecks,
                        iconColor: AppColors.violet,
                        iconBackground: AppColors.giveawayAboutIcon,
                        background: AppColors.giveawayAboutCard,
                        title: l10n.giveawaySteps,
                        child: Column(
                          children: [
                            for (final step in giveaway.steps)
                              GiveawayStepTile(
                                step: step,
                                progress: details.progress[step.id],
                                busy: state.busyStepId == step.id,
                                enabled: canAct && state.busyStepId == null,
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (state.winners?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 12),
                      GiveawayInfoCard(
                        icon: LucideIcons.trophy,
                        iconColor: AppColors.violet,
                        iconBackground: AppColors.giveawayAboutIcon,
                        background: AppColors.giveawayAboutCard,
                        title: l10n.giveawayResults,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final winner in state.winners!)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  l10n.giveawayWinnerRow(winner.rank, winner.participationNumber),
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      l10n.giveawayFreeNote,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    SizedBox(height: bottomSpace),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The single call to action, from the backend state of the giveaway and
  /// the user's entry.
  Widget _cta(BuildContext context, GiveawayDetailsState state, GiveawayDetails details) {
    final l10n = context.l10n;
    final giveaway = details.giveaway;
    final entry = details.entry;
    final full =
        giveaway.maxParticipants != null && giveaway.participants >= giveaway.maxParticipants!;
    if (entry != null) {
      return GiveawayJoinButton(
        label: entry.active ? l10n.giveawayViewTicket : l10n.giveawayDisqualified,
        icon: LucideIcons.ticket,
        onPressed: entry.active
            ? () => context.push(
                Routes.ticket,
                extra: TicketArgs(
                  title: giveaway.title.of(context),
                  number: entry.participationNumber,
                ),
              )
            : null,
      );
    }
    final unavailable = giveaway.isUpcoming
        ? l10n.giveawayUpcoming
        : !giveaway.isActive
        ? l10n.giveawayClosed
        : full
        ? l10n.giveawayFull
        : null;
    if (unavailable != null) return GiveawayJoinButton(label: unavailable, onPressed: null);
    final remaining = details.remainingRequiredSteps;
    return GiveawayJoinButton(
      label: remaining.isEmpty ? l10n.giveawayJoin : l10n.giveawayCompleteSteps,
      busy: state.entering,
      onPressed: remaining.isEmpty ? () => _join(giveaway) : null,
    );
  }
}

/// Back button over the hero, kept below the status bar (no title: the
/// artwork runs edge to edge).
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Material(
          color: Colors.white.withValues(alpha: .85),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).maybePop(),
            // Material arrows mirror themselves in RTL.
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          ),
        ),
      ),
    ),
  );
}

/// Fixed bottom area holding the CTA above the gesture inset, on a white
/// fade so scrolled content never collides with it.
class _JoinBar extends StatelessWidget {
  const _JoinBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x00ffffff), Colors.white],
        stops: [0, .35],
      ),
    ),
    child: SafeArea(
      top: false,
      child: Padding(padding: const EdgeInsets.fromLTRB(20, 22, 20, 12), child: child),
    ),
  );
}
