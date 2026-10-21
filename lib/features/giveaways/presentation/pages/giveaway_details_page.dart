import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/giveaway_entities.dart';
import '../bloc/giveaway_cubits.dart';
import '../widgets/giveaway_steps.dart';
import '../widgets/giveaway_visuals.dart';
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

class _GiveawayDetailsView extends StatelessWidget {
  const _GiveawayDetailsView();

  Future<void> _join(BuildContext context, Giveaway giveaway) async {
    final cubit = context.read<GiveawayDetailsCubit>();
    final entry = await cubit.enter();
    if (!context.mounted) return;
    if (entry == null) {
      if (cubit.state.error != null) showErrorSnackBar(context, cubit.state.error!);
      return;
    }
    await context.push(
      Routes.ticket,
      extra: TicketArgs(title: giveaway.title.of(context), number: entry.participationNumber),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.giveawayDetailsTitle)),
      body: BlocBuilder<GiveawayDetailsCubit, GiveawayDetailsState>(
        builder: (context, state) {
          final cubit = context.read<GiveawayDetailsCubit>();
          final details = state.details;
          if (details == null) {
            return state.status == GiveawayDetailsStatus.failed
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: ErrorStateView(error: state.error!, onRetry: cubit.load),
                  )
                : const LoadingView();
          }
          final giveaway = details.giveaway;
          final entry = details.entry;
          final canAct = giveaway.isActive && entry == null;
          final remaining = details.remainingRequiredSteps;
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: const Color(0xffe5e2ff),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Center(
                    child: SizedBox(
                      height: 210,
                      child: GiveawayArt(
                        imageUrl: giveaway.imageUrl,
                        title: giveaway.title,
                        prize: giveaway.prize,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Text(giveaway.title.of(context), style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  giveawaySubtitle(context, giveaway),
                  style: const TextStyle(color: AppColors.muted, fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (giveaway.organizer.isNotEmpty) l10n.giveawayOrganizer(giveaway.organizer),
                    l10n.giveawayParticipants(giveaway.participants),
                  ].join(' · '),
                  style: const TextStyle(color: AppColors.muted, fontSize: 14),
                ),
                if (giveaway.description.of(context).isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    giveaway.description.of(context),
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
                if (giveaway.prize.of(context).isNotEmpty)
                  _section(context, l10n.giveawayPrize, giveaway.prize.of(context)),
                if (giveaway.rules.of(context).isNotEmpty)
                  _section(context, l10n.giveawayRules, giveaway.rules.of(context)),
                if (giveaway.steps.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text(l10n.giveawaySteps, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  for (final step in giveaway.steps)
                    GiveawayStepTile(
                      step: step,
                      progress: details.progress[step.id],
                      busy: state.busyStepId == step.id,
                      enabled: canAct && state.busyStepId == null,
                    ),
                ],
                if (state.winners?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 22),
                  Text(l10n.giveawayResults, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  for (final winner in state.winners!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        l10n.giveawayWinnerRow(winner.rank, winner.participationNumber),
                        style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
                const SizedBox(height: 24),
                Text(
                  l10n.giveawayFreeNote,
                  style: const TextStyle(color: AppColors.muted, fontSize: 14),
                ),
                const SizedBox(height: 18),
                if (entry != null)
                  GradientButton(
                    entry.active ? l10n.giveawayViewTicket : l10n.giveawayDisqualified,
                    onPressed: entry.active
                        ? () => context.push(
                            Routes.ticket,
                            extra: TicketArgs(
                              title: giveaway.title.of(context),
                              number: entry.participationNumber,
                            ),
                          )
                        : null,
                  )
                else if (giveaway.isUpcoming)
                  GradientButton(l10n.giveawayUpcoming, onPressed: null)
                else if (!giveaway.isActive)
                  GradientButton(l10n.giveawayClosed, onPressed: null)
                else
                  GradientButton(
                    remaining.isEmpty ? l10n.giveawayJoin : l10n.giveawayCompleteSteps,
                    busy: state.entering,
                    onPressed: remaining.isEmpty ? () => _join(context, giveaway) : null,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section(BuildContext context, String title, String body) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(body, style: const TextStyle(fontSize: 15, height: 1.5)),
      ],
    ),
  );
}
