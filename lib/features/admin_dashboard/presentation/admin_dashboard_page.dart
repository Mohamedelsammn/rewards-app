import 'package:flutter/material.dart';
import '../../../core/theme/app_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/models/giveaway.dart';
import '../../../shared/models/giveaway_category.dart';
import '../../../shared/repositories/category_repository.dart';
import '../../create_giveaway/presentation/create_giveaway_page.dart';
import '../../giveaway_analytics/presentation/giveaway_analytics_page.dart';
import 'bloc/admin_dashboard_cubit.dart';
import 'bloc/admin_dashboard_state.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminDashboardCubit(getIt(), getIt(), getIt())
        ..load()
        ..subscribeToRealtime(),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      // This page renders inside AdminShell's GlassScaffold, which floats
      // its own Liquid Glass bottom nav bar ABOVE this inner Scaffold in a
      // separate Stack layer -- this Scaffold has no `bottomNavigationBar`
      // of its own, so it doesn't know to reserve space for that bar and a
      // default-positioned FAB sits underneath/behind it. Padding the FAB
      // up by the nav's actual computed footprint (pill height + its own
      // padding + the device safe area -- see AppBottomNav.footprint, the
      // single source of truth GlassScaffold itself uses) keeps it clear on
      // every screen size without a hardcoded, device-specific offset.
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: AppBottomNav.footprint(context)),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          // No manual reload here on return -- AdminDashboardCubit reloads
          // itself the moment GiveawayRepository.createGiveaway() confirms
          // success (see its `giveawayCreated` stream subscription), so a
          // second explicit `.load()` here would just be a redundant
          // network request racing the same reload.
          onPressed: () => Navigator.of(
            context,
          ).push<bool>(MaterialPageRoute(builder: (_) => const CreateGiveawayPage())),
          child: const Icon(AppIcons.add, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
          builder: (context, state) {
            if (state.status == AdminDashboardStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == AdminDashboardStatus.error) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.adminDashboardCouldNotLoad, style: AppTypography.bodyMd),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () => context.read<AdminDashboardCubit>().load(),
                      child: Text(l10n.commonRetry),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => context.read<AdminDashboardCubit>().load(),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.containerPadding,
                  AppSpacing.containerPadding,
                  AppSpacing.containerPadding,
                  // Nav footprint + FAB clearance so the last card and the
                  // floating "+" button are never covered.
                  AppBottomNav.footprint(context) + AppSpacing.xxl,
                ),
                children: [
                  Text(
                    l10n.adminDashboardGoodDay,
                    style: AppTypography.headlineLg.copyWith(fontSize: 26),
                  ),
                  Text(l10n.adminDashboardAdministrator, style: AppTypography.bodyMd),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: AppIcons.campaign,
                          label: l10n.adminDashboardActiveGiveaways,
                          value: '${state.activeCount}',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _StatCard(
                          icon: AppIcons.participants,
                          label: l10n.adminDashboardTotalParticipants,
                          value: '${state.totalParticipants}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: AppIcons.checkCircle,
                          label: l10n.adminDashboardFinished,
                          value: '${state.finishedCount}',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _StatCard(
                          icon: AppIcons.trophy,
                          label: l10n.adminDashboardWinnersSelected,
                          value: '${state.winnersSelectedCount}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _CampaignSections(state: state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: AppTypography.labelSm),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.headlineMd.copyWith(fontSize: 22)),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.giveaway,
    required this.isEnded,
    this.isUpcoming = false,
    this.categoryName,
  });

  final Giveaway giveaway;
  final bool isEnded;
  final bool isUpcoming;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
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
              // Same Active/Ended badge language already used on the User
              // side (My Giveaways) and Giveaway Analytics -- one status
              // badge look across the whole app.
              PositionedDirectional(
                top: AppSpacing.sm,
                end: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUpcoming
                        ? AppColors.primary
                        : isEnded
                        ? AppColors.outline
                        : AppColors.success,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    isUpcoming
                        ? l10n.browseUpcoming
                        : isEnded
                        ? l10n.statusEnded
                        : l10n.statusActive,
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
                Text(giveaway.title, style: AppTypography.headlineMd.copyWith(fontSize: 18)),
                if (isUpcoming) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${l10n.scheduleStartTime}: ${MaterialLocalizations.of(context).formatMediumDate(giveaway.startsAt)} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(giveaway.startsAt))}',
                    style: AppTypography.bodyMd,
                  ),
                  Text(
                    '${l10n.createGiveawayEndDate}: ${MaterialLocalizations.of(context).formatMediumDate(giveaway.endsAt)} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(giveaway.endsAt))}',
                    style: AppTypography.bodyMd,
                  ),
                  Text(categoryName ?? l10n.categoryUncategorized, style: AppTypography.labelSm),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.adminDashboardParticipantsCount(giveaway.participantCount),
                  style: AppTypography.bodyMd,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GiveawayAnalyticsPage(giveawayId: giveaway.id),
                      ),
                    ),
                    child: Text(l10n.adminDashboardViewAnalytics),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(AppIcons.edit),
                    label: Text(l10n.categoryEditGiveaway),
                    onPressed: () async {
                      final changed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(builder: (_) => CreateGiveawayPage(giveaway: giveaway)),
                      );
                      if (changed == true && context.mounted) {
                        context.read<AdminDashboardCubit>().load();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignSections extends StatefulWidget {
  const _CampaignSections({required this.state});
  final AdminDashboardState state;

  @override
  State<_CampaignSections> createState() => _CampaignSectionsState();
}

class _CampaignSectionsState extends State<_CampaignSections> {
  String _filter = 'all';
  List<GiveawayCategory> _categories = const [];

  @override
  void initState() {
    super.initState();
    if (getIt.isRegistered<CategoryRepository>()) _loadCategories();
  }

  Future<void> _loadCategories() async {
    final result = await getIt<CategoryRepository>().getCategories();
    if (!mounted) return;
    result.fold((_) {}, (rows) => setState(() => _categories = rows));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final all = [
      ...widget.state.upcomingCampaigns,
      ...widget.state.activeCampaigns,
      ...widget.state.endedCampaigns,
    ];
    final rows = switch (_filter) {
      'upcoming' => widget.state.upcomingCampaigns,
      'active' => widget.state.activeCampaigns,
      'ended' => widget.state.endedCampaigns,
      _ => all,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            _filterChip('all', l10n.adminFilterAll),
            _filterChip('upcoming', l10n.browseUpcoming),
            _filterChip('active', l10n.statusActive),
            _filterChip('ended', l10n.statusEnded),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(child: Text(l10n.adminNoFilteredGiveaways, style: AppTypography.bodyMd)),
          )
        else
          for (final giveaway in rows) ...[
            _CampaignCard(
              giveaway: giveaway,
              isEnded: giveaway.effectiveStatus == GiveawayStatus.ended,
              isUpcoming: giveaway.effectiveStatus == GiveawayStatus.scheduled,
              categoryName: _categoryName(giveaway),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }

  String? _categoryName(Giveaway giveaway) {
    final id = giveaway.categoryId;
    if (id == null) return null;
    for (final category in _categories) {
      if (category.id == id) return category.label(Localizations.localeOf(context).languageCode);
    }
    return null;
  }

  Widget _filterChip(String value, String label) => ChoiceChip(
    label: Text(label),
    selected: _filter == value,
    onSelected: (_) => setState(() => _filter = value),
  );
}
