import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_visuals.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/secure_storage_service.dart';
import '../../../shared/models/giveaway.dart';
import '../../../shared/repositories/category_repository.dart';
import '../../../shared/repositories/notification_repository.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../giveaway_details/presentation/giveaway_details_page.dart';
import '../../notifications/presentation/notifications_page.dart';
import 'bloc/user_home_cubit.dart';
import 'bloc/user_home_state.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        UserHomeCubit(
            getIt(),
            getIt(),
            categories: getIt.isRegistered<CategoryRepository>()
                ? getIt<CategoryRepository>()
                : null,
          )
          ..load()
          ..loadCategories()
          ..subscribeToRealtime(),
    child: const _UserHomeView(),
  );
}

class _UserHomeView extends StatefulWidget {
  const _UserHomeView();
  @override
  State<_UserHomeView> createState() => _UserHomeViewState();
}

class _UserHomeViewState extends State<_UserHomeView> {
  final _search = TextEditingController();
  Timer? _clock;
  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<UserHomeCubit, UserHomeState>(
          builder: (context, state) {
            final cubit = context.read<UserHomeCubit>();
            return RefreshIndicator(
              onRefresh: () async {
                await Future.wait([cubit.load(forceRefresh: true), cubit.loadCategories()]);
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.extentAfter < 500 && state.failure == null) {
                    cubit.loadMore();
                  }
                  return false;
                },
                child: CustomScrollView(
                  key: const PageStorageKey('home-grid'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: _Header()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                        child: TextField(
                          controller: _search,
                          onChanged: (q) {
                            cubit.onSearchChanged(q);
                            setState(() {});
                          },
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          decoration: InputDecoration(
                            hintText: l10n.userHomeSearchHint,
                            prefixIcon: const Icon(AppIcons.search, size: AppVisuals.icon),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: l10n.browseClearSearch,
                                    icon: const Icon(AppIcons.close, size: AppVisuals.icon),
                                    onPressed: () {
                                      _search.clear();
                                      cubit.clearSearch();
                                      setState(() {});
                                    },
                                  ),
                            filled: true,
                            fillColor: const Color(0xfff7f6fc),
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppVisuals.fieldRadius),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppVisuals.fieldRadius),
                              borderSide: const BorderSide(color: AppVisuals.divider),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppVisuals.fieldRadius),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (state.categoriesLoading && state.categories.isEmpty)
                      const SliverToBoxAdapter(child: _CategorySkeletons())
                    else
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 64,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: state.categories.length + 1,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final category = i == 0 ? null : state.categories[i - 1];
                              final selected = state.categoryId == category?.id;
                              return ChoiceChip(
                                showCheckmark: false,
                                selected: selected,
                                avatar: Icon(
                                  category == null
                                      ? AppIcons.categories
                                      : AppIcons.category(category.icon),
                                  size: AppVisuals.smallIcon,
                                  color: selected ? Colors.white : AppColors.primary,
                                ),
                                label: Text(
                                  category?.label(Localizations.localeOf(context).languageCode) ??
                                      l10n.browseAll,
                                ),
                                selectedColor: AppColors.primary,
                                backgroundColor: AppVisuals.chipSurface,
                                materialTapTargetSize: MaterialTapTargetSize.padded,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppVisuals.chipRadius),
                                ),
                                labelStyle: TextStyle(
                                  color: selected ? Colors.white : AppColors.onSurface,
                                  fontSize: 12,
                                ),
                                onSelected: (_) => cubit.selectCategory(category?.id),
                              );
                            },
                          ),
                        ),
                      ),
                    if (state.categoryFailure != null)
                      SliverToBoxAdapter(
                        child: TextButton(
                          onPressed: cubit.loadCategories,
                          child: Text(l10n.browseCategoriesRetry),
                        ),
                      ),
                    if (state.status == UserHomeStatus.loading)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        sliver: SliverLayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.crossAxisExtent >= 700 ? 3 : 2;
                            final width =
                                (constraints.crossAxisExtent - (columns - 1) * 10) / columns;
                            final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
                            return SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (_, _) => const _GiveawayCardSkeleton(),
                                childCount: 6,
                              ),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 12,
                                mainAxisExtent: _giveawayCardExtent(width, scale),
                              ),
                            );
                          },
                        ),
                      )
                    else if (state.status == UserHomeStatus.error)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(l10n.commonSomethingWrong),
                              TextButton(onPressed: cubit.load, child: Text(l10n.commonRetry)),
                            ],
                          ),
                        ),
                      )
                    else if (state.allGiveaways.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(AppIcons.gift, size: 48, color: AppColors.primary),
                              const SizedBox(height: 12),
                              Text(l10n.browseNoGiveaways),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      if (state.searchQuery.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: Text(l10n.browseSearchResults, style: AppTypography.labelSm),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        sliver: SliverLayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.crossAxisExtent >= 700 ? 3 : 2;
                            final width =
                                (constraints.crossAxisExtent - (columns - 1) * 10) / columns;
                            final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
                            return SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => GiveawayBrowseCard(giveaway: state.allGiveaways[i]),
                                childCount: state.allGiveaways.length,
                              ),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 12,
                                mainAxisExtent: _giveawayCardExtent(width, scale),
                              ),
                            );
                          },
                        ),
                      ),
                      if (state.loadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      if (state.hasMore && !state.loadingMore)
                        SliverToBoxAdapter(
                          child: Center(
                            child: TextButton(
                              onPressed: cubit.loadMore,
                              child: Text(
                                state.failure == null ? l10n.browseLoadMore : l10n.commonRetry,
                              ),
                            ),
                          ),
                        ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

double _giveawayCardExtent(double width, double textScale) =>
    math.max(240, width * .88 + 110 * textScale);

class _CategorySkeletons extends StatelessWidget {
  const _CategorySkeletons();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 64,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) => Container(
        width: i == 0 ? 86 : 126,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xfff1eff8),
          borderRadius: BorderRadius.circular(AppVisuals.chipRadius),
        ),
      ),
    ),
  );
}

class _GiveawayCardSkeleton extends StatelessWidget {
  const _GiveawayCardSkeleton();
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      border: Border.all(color: const Color(0xfff0edf7)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(flex: 6, child: ColoredBox(color: Color(0xfff0eff5))),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xfff0eff5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 11,
                  width: 74,
                  decoration: BoxDecoration(
                    color: const Color(0xfff0eff5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const Spacer(),
                Container(
                  height: 11,
                  width: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xfff0eff5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class GiveawayBrowseCard extends StatelessWidget {
  const GiveawayBrowseCard({super.key, required this.giveaway});
  final Giveaway giveaway;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = giveaway.effectiveStatus;
    final upcoming = status == GiveawayStatus.scheduled;
    final soon =
        status == GiveawayStatus.active && giveaway.timeRemaining <= const Duration(hours: 24);
    final color = upcoming
        ? AppVisuals.upcoming
        : status == GiveawayStatus.ended
        ? AppVisuals.ended
        : soon
        ? AppVisuals.endingSoon
        : AppVisuals.active;
    final label = upcoming
        ? l10n.browseUpcoming
        : status == GiveawayStatus.ended
        ? l10n.statusEnded
        : soon
        ? l10n.browseEndingSoon
        : l10n.statusActive;
    final remaining = giveaway.timeRemaining;
    final locale = Localizations.localeOf(context).languageCode;
    final time = upcoming
        ? '${l10n.browseStartsIn} ${DateFormat.MMMd(locale).add_Hm().format(giveaway.startsAt)}'
        : status == GiveawayStatus.ended
        ? l10n.statusEnded
        : '${remaining.inDays}${l10n.browseDayShort} ${remaining.inHours % 24}${l10n.browseHourShort}';
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: const Color(0x184c39c7),
      borderRadius: BorderRadius.circular(AppVisuals.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            settings: giveawayDetailsSettings(giveaway.id),
            builder: (_) => GiveawayDetailsPage(giveawayId: giveaway.id, initialGiveaway: giveaway),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Colors.white),
                  LayoutBuilder(
                    builder: (context, constraints) => AppNetworkImage(
                      url: giveaway.imageUrl,
                      fit: BoxFit.contain,
                      memCacheWidth: (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                          .ceil()
                          .clamp(1, 1024),
                    ),
                  ),
                  PositionedDirectional(
                    top: 8,
                    start: 8,
                    end: 8,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (status != GiveawayStatus.ended)
                    PositionedDirectional(
                      start: 7,
                      end: 7,
                      bottom: 7,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .92),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(upcoming ? AppIcons.calendar : AppIcons.clock, size: 12),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  time,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    giveaway.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    giveaway.organizerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.outline),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(AppIcons.participants, size: 14, color: AppColors.outline),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${NumberFormat.compact(locale: locale).format(giveaway.participantCount)} ${l10n.browseJoined}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: AppColors.outline),
                        ),
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

class _Header extends StatefulWidget {
  const _Header();

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  String? _fullName;
  StreamSubscription<void>? _identitySub;

  @override
  void initState() {
    super.initState();
    _loadName();
    _identitySub = getIt<SecureStorageService>().identityChanged.listen((_) => _loadName());
  }

  Future<void> _loadName() async {
    final name = await getIt<SecureStorageService>().cachedFullName;
    if (!mounted) return;
    setState(() => _fullName = name);
  }

  @override
  void dispose() {
    _identitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = _fullName;
    final displayName = (name == null || name.trim().isEmpty) ? l10n.userHomeGuest : name;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPadding,
        AppSpacing.md,
        AppSpacing.containerPadding,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.userHomeWelcomeBack, style: AppTypography.bodyMd.copyWith(fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  style: AppTypography.headlineMd.copyWith(fontSize: 23, color: AppColors.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const _NotificationBell(),
        ],
      ),
    );
  }
}

/// Opens [NotificationsPage] and shows a small unread-count dot, refreshed
/// whenever the user returns from that page (e.g. after marking items read).
class _NotificationBell extends StatefulWidget {
  const _NotificationBell();

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  bool _hasUnread = false;

  @override
  void initState() {
    super.initState();
    _refreshUnreadState();
  }

  Future<void> _refreshUnreadState() async {
    final result = await getIt<NotificationRepository>().getUnreadCount();
    if (!mounted) return;
    result.fold((_) {}, (count) => setState(() => _hasUnread = count > 0));
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
    await _refreshUnreadState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.notificationsTitle,
      child: InkWell(
        onTap: _openNotifications,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.bell, size: AppVisuals.icon),
              ),
              if (_hasUnread)
                PositionedDirectional(
                  top: 4,
                  end: 4,
                  child: Container(
                    key: const ValueKey('notification_unread_badge'),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
