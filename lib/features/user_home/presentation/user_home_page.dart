import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/giveaway.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../giveaway_details/presentation/giveaway_details_page.dart';
import 'bloc/user_home_cubit.dart';
import 'bloc/user_home_state.dart';

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

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserHomeCubit(getIt())..load(),
      child: const _UserHomeView(),
    );
  }
}

class _UserHomeView extends StatelessWidget {
  const _UserHomeView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: BlocBuilder<UserHomeCubit, UserHomeState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<UserHomeCubit>().load(forceRefresh: true),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Header()),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerPadding),
                  sliver: SliverToBoxAdapter(child: _SearchField()),
                ),
                if (state.status == UserHomeStatus.loading)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                else if (state.status == UserHomeStatus.error)
                  SliverFillRemaining(
                    child: _ErrorState(
                      onRetry: () => context.read<UserHomeCubit>().load(forceRefresh: true),
                    ),
                  )
                else if (state.allGiveaways.isEmpty)
                  const SliverFillRemaining(child: _EmptyState())
                else ...[
                  if (state.searchQuery.isEmpty && state.featured != null) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.containerPadding,
                        AppSpacing.lg,
                        AppSpacing.containerPadding,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(child: _FeaturedBanner(giveaway: state.featured!)),
                    ),
                  ],
                  if (state.searchQuery.isEmpty && state.popular.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.containerPadding,
                        AppSpacing.xl,
                        0,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          l10n.userHomePopularGiveaways,
                          style: AppTypography.headlineMd.copyWith(fontSize: 20),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.containerPadding,
                            AppSpacing.md,
                            AppSpacing.containerPadding,
                            0,
                          ),
                          itemCount: state.popular.length,
                          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                          itemBuilder: (context, i) => _PopularCard(giveaway: state.popular[i]),
                        ),
                      ),
                    ),
                  ],
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.containerPadding,
                      AppSpacing.xl,
                      AppSpacing.containerPadding,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        l10n.userHomeAllGiveaways,
                        style: AppTypography.headlineMd.copyWith(fontSize: 20),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.containerPadding,
                      AppSpacing.md,
                      AppSpacing.containerPadding,
                      AppSpacing.md,
                    ),
                    sliver: SliverList.separated(
                      itemCount: state.filteredGiveaways.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, i) =>
                          _GiveawayListTile(giveaway: state.filteredGiveaways[i]),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPadding,
        AppSpacing.md,
        AppSpacing.containerPadding,
        0,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryContainer,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.userHomeWelcomeBack, style: AppTypography.labelSm),
                Text(
                  l10n.userHomeGuest,
                  style: AppTypography.headlineMd.copyWith(fontSize: 18, color: AppColors.primary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: TextField(
        onTapOutside: (details) => FocusScope.of(context).unfocus(),
        onChanged: (q) => context.read<UserHomeCubit>().onSearchChanged(q),
        decoration: InputDecoration(
          hintText: l10n.userHomeSearchHint,
          prefixIcon: const Icon(Icons.search_rounded),
        ),
      ),
    );
  }
}

class _FeaturedBanner extends StatelessWidget {
  const _FeaturedBanner({required this.giveaway});
  final Giveaway giveaway;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => GiveawayDetailsPage(giveawayId: giveaway.id))),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WhiteChip(
                    icon: Icons.card_giftcard_rounded,
                    label: l10n.userHomeFeaturedGiveaway,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    giveaway.title,
                    style: AppTypography.headlineMd.copyWith(color: Colors.white, fontSize: 22),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    giveaway.prizeDescription,
                    style: AppTypography.bodyMd.copyWith(color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: AspectRatio(
                aspectRatio: 1,
                child: AppNetworkImage(
                  url: giveaway.imageUrl,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhiteChip extends StatelessWidget {
  const _WhiteChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.labelSm.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

class _PopularCard extends StatelessWidget {
  const _PopularCard({required this.giveaway});
  final Giveaway giveaway;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => GiveawayDetailsPage(giveawayId: giveaway.id))),
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.4,
                  child: AppNetworkImage(
                    url: giveaway.imageUrl,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: _WhiteChip(
                    icon: Icons.people_alt_rounded,
                    label: l10n.userHomeJoinedCount(giveaway.participantCount),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(giveaway.organizerName.toUpperCase(), style: AppTypography.labelSm),
            Text(
              giveaway.title,
              style: AppTypography.bodyMd,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _GiveawayListTile extends StatelessWidget {
  const _GiveawayListTile({required this.giveaway});
  final Giveaway giveaway;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => GiveawayDetailsPage(giveawayId: giveaway.id))),
      child: Container(
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      giveaway.isJoinable ? l10n.statusActive : _statusLabel(l10n, giveaway.status),
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
                  Text(giveaway.organizerName.toUpperCase(), style: AppTypography.labelSm),
                  const SizedBox(height: 2),
                  Text(giveaway.title, style: AppTypography.headlineMd.copyWith(fontSize: 16)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    giveaway.prizeDescription,
                    style: AppTypography.bodyMd,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.userHomeJoinedCount(giveaway.participantCount),
                        style: AppTypography.labelSm,
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GiveawayDetailsPage(giveawayId: giveaway.id),
                          ),
                        ),
                        child: Text(l10n.userHomeViewDetails),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Text(
        l10n.userHomeNoActiveGiveaways,
        style: AppTypography.bodyMd,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.outline, size: 40),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.userHomeCouldNotLoad, style: AppTypography.bodyMd),
          const SizedBox(height: AppSpacing.md),
          TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }
}
