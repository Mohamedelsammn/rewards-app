import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../app/router/routes.dart';
import '../giveaway_navigation.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/paged_list_state.dart';
import '../../../../core/widgets/headers.dart';
import '../../../../core/widgets/paged_list_view.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/selectors.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/giveaway_entities.dart';
import '../bloc/giveaway_cubits.dart';
import '../widgets/giveaway_visuals.dart';
import 'ticket_page.dart';

/// `GET /me/entries` with a result filter.
class MyGiveawaysPage extends StatelessWidget {
  const MyGiveawaysPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => MyEntriesCubit(sl())..refresh(),
    child: Builder(
      builder: (context) {
        final l10n = context.l10n;
        final cubit = context.read<MyEntriesCubit>();
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: BlocBuilder<MyEntriesCubit, PagedListState<GiveawayEntry, EntryResult?>>(
              builder: (context, state) => PagedListView<GiveawayEntry, EntryResult?>(
                state: state,
                onRefresh: cubit.refresh,
                onLoadMore: cubit.loadMore,
                emptyMessage: l10n.myGiveawaysEmpty,
                skeletonRow: const SkeletonRow(
                  leadingSize: 82,
                  leadingRadius: 19,
                  lines: [170, 90, 110],
                  trailingWidth: 32,
                  trailingHeight: 32,
                ),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                header: [
                  SecondaryHeader(
                    title: l10n.myGiveawaysTitle,
                    subtitle: l10n.myGiveawaysSubtitle,
                    art: const HeaderArt(HeaderArtKind.gift),
                  ),
                  const SizedBox(height: 20),
                  FilterPills<EntryResult?>(
                    options: [
                      SelectorOption(null, l10n.resultAll),
                      SelectorOption(EntryResult.pending, l10n.resultPending),
                      SelectorOption(EntryResult.won, l10n.resultWon),
                      SelectorOption(EntryResult.notSelected, l10n.resultNotSelected),
                    ],
                    selected: state.filter,
                    onChanged: cubit.setFilter,
                  ),
                  const SizedBox(height: 18),
                ],
                itemBuilder: (context, entry) => _EntryCard(entry: entry),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final GiveawayEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = entry.giveawayTitle.of(context);
    final (status, color) = !entry.active
        ? (l10n.entryDisqualified, AppColors.danger)
        : switch (entry.result) {
            EntryResult.won => (l10n.resultWon, AppColors.success),
            EntryResult.notSelected => (l10n.resultNotSelected, AppColors.muted),
            _ => (l10n.resultPending, AppColors.violet),
          };
    return InkWell(
      onTap: () => entry.result == EntryResult.pending && entry.active
          ? context.push(
              Routes.ticket,
              extra: TicketArgs(title: title, number: entry.participationNumber),
            )
          : openGiveawayFromTap(context, entry.giveawayId),
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(color: Color(0x127965b5), blurRadius: 21, offset: Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 82,
              height: 82,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xffeae5ff),
                borderRadius: BorderRadius.circular(19),
              ),
              child: GiveawayArt(imageUrl: entry.giveawayImageUrl, title: entry.giveawayTitle),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    key: ValueKey('ticket-${entry.participationNumber}'),
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: entry.participationNumber));
                      if (context.mounted) showAppSnackBar(context, l10n.ticketCopied);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.tint,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.ticket, color: AppColors.violet, size: 15),
                          const SizedBox(width: 7),
                          Text(
                            entry.participationNumber,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              color: AppColors.violet,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            const CircleArrow(),
          ],
        ),
      ),
    );
  }
}
