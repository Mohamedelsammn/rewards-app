import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../wallet/presentation/bloc/wallet_cubit.dart';
import '../../domain/home_feed.dart';
import '../bloc/home_cubit.dart';
import '../widgets/home_sections.dart';
import '../widgets/home_skeleton.dart';
import '../widgets/points_header.dart';

/// Home tab: balance header, search, categories rail, featured rewards and
/// giveaways. Everything comes from `GET /home` / `GET /search`.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => HomeCubit(sl())..load(), child: const _HomeView());
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final home = context.read<HomeCubit>();
    await Future.wait([home.load(), context.read<WalletCubit>().load()]);
    if (_search.text.trim().isNotEmpty) home.search(_search.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final feed = state.isSearching ? state.results : state.feed;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            key: const PageStorageKey('home'),
            padding: EdgeInsets.zero,
            children: [
              PointsHeader(searchController: _search, onSearch: context.read<HomeCubit>().search),
              // A failed refresh keeps the feed below and says so here.
              if (!state.isSearching && state.status == HomeStatus.ready && state.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: RefreshErrorBanner(onRetry: context.read<HomeCubit>().load),
                ),
              ..._content(context, state, feed, l10n),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _content(
    BuildContext context,
    HomeState state,
    HomeFeed? feed,
    AppLocalizations l10n,
  ) {
    if (state.isSearching && (state.searching || feed == null)) {
      final error = state.searchError;
      return [
        if (error != null)
          Padding(
            padding: const EdgeInsets.all(20),
            child: ErrorStateView(
              error: error,
              onRetry: () => context.read<HomeCubit>().search(_search.text),
            ),
          )
        else
          const HomeSkeleton(),
      ];
    }
    if (!state.isSearching && state.status == HomeStatus.loading) return const [HomeSkeleton()];
    if (!state.isSearching && state.status == HomeStatus.failed) {
      return [
        Padding(
          padding: const EdgeInsets.all(20),
          child: ErrorStateView(error: state.error!, onRetry: context.read<HomeCubit>().load),
        ),
      ];
    }
    final data = feed ?? const HomeFeed();
    if (data.isEmpty) {
      return [
        if (state.isSearching)
          AppEmptyState(
            icon: LucideIcons.searchX,
            title: l10n.homeNoResults,
            message: l10n.homeNoResultsBody,
          )
        else
          AppEmptyState(
            key: const ValueKey('home-empty'),
            icon: LucideIcons.gift,
            title: l10n.homeEmptyTitle,
            message: l10n.homeEmptyBody,
          ),
      ];
    }
    return [
      if (data.categories.isNotEmpty) ...[
        SectionHeader(
          title: l10n.homeAvailableRewards,
          onSeeAll: () => context.go(Routes.categories),
        ),
        CategoryRail(categories: data.categories),
      ],
      if (data.featuredProducts.isNotEmpty) ...[
        SectionHeader(title: l10n.homeFeaturedRewards),
        FeaturedProductsRow(
          products: data.featuredProducts,
          categories: [...data.categories, ...state.feed.categories],
        ),
      ],
      if (data.giveaways.isNotEmpty) ...[
        SectionHeader(title: l10n.homeGiveaways, onSeeAll: () => context.push(Routes.giveaways)),
        HomeGiveaways(giveaways: data.giveaways),
      ],
    ];
  }
}
