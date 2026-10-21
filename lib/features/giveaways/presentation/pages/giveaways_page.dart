import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/paged_list_state.dart';
import '../../../../core/widgets/headers.dart';
import '../../../../core/widgets/selectors.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/giveaway_entities.dart';
import '../bloc/giveaway_cubits.dart';
import '../widgets/giveaway_visuals.dart';

/// All giveaways with Available / Coming soon / Ended tabs.
class GiveawaysPage extends StatelessWidget {
  const GiveawaysPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => GiveawaysListCubit(sl())..refresh(),
    child: const _GiveawaysView(),
  );
}

class _GiveawaysView extends StatelessWidget {
  const _GiveawaysView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<GiveawaysListCubit>();
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: BlocBuilder<GiveawaysListCubit, PagedListState<Giveaway, GiveawayListFilter>>(
          builder: (context, state) => NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.extentAfter < 400) cubit.loadMore();
              return false;
            },
            child: RefreshIndicator(
              onRefresh: cubit.refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SecondaryHeader(
                    title: l10n.giveawaysTitle,
                    subtitle: l10n.giveawaysSubtitle,
                    art: const HeaderArt(HeaderArtKind.gift),
                  ),
                  const SizedBox(height: 20),
                  SegmentedTabs<GiveawayListFilter>(
                    options: [
                      SelectorOption(GiveawayListFilter.available, l10n.giveawayAvailable),
                      SelectorOption(GiveawayListFilter.upcoming, l10n.giveawayUpcoming),
                      SelectorOption(GiveawayListFilter.ended, l10n.giveawayEnded),
                    ],
                    selected: state.filter,
                    onChanged: cubit.setFilter,
                  ),
                  const SizedBox(height: 18),
                  switch (state.status) {
                    PagedStatus.loading => const Padding(
                      padding: EdgeInsets.all(40),
                      child: LoadingView(),
                    ),
                    PagedStatus.failed => ErrorStateView(
                      error: state.error!,
                      onRetry: cubit.refresh,
                    ),
                    PagedStatus.ready when state.items.isEmpty => EmptyCard(l10n.giveawaysEmpty),
                    PagedStatus.ready => GiveawayGrid(
                      giveaways: state.items,
                      onTap: (giveaway) => context.push(Routes.giveaway(giveaway.id)),
                    ),
                  },
                  if (state.loadingMore)
                    const Padding(padding: EdgeInsets.all(16), child: LoadingView()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
