import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/injection.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/notification_service.dart';
import '../../../services/ads/ad_service.dart';
import '../../../shared/widgets/ad_banner.dart';
import '../../../services/secure_storage_service.dart';
import '../../../shared/utils/notification_routing.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/user_tab_scaffold.dart';
import '../../my_giveaways/presentation/my_giveaways_page.dart';
import '../../settings/presentation/settings_page.dart';
import 'user_home_page.dart';

/// User bottom nav shell: Home / My Giveaways / Settings
/// (implementation-plan.md §9, tasks.md T07-04). Uses an IndexedStack so
/// each tab preserves its scroll/state across switches. The floating pill
/// nav bar uses liquid_glass_widgets' GlassTabBar -- kept deliberately
/// restrained (default blur/blend, no extras) since glass is reserved for
/// the navigation/control layer, not the whole app.
class UserHomeShell extends StatefulWidget {
  const UserHomeShell({super.key});

  @override
  State<UserHomeShell> createState() => _UserHomeShellState();
}

class _UserHomeShellState extends State<UserHomeShell> {
  int _index = 0;
  StreamSubscription<Map<String, dynamic>>? _notificationTapSub;
  RealtimeChannel? _winnerNotificationChannel;

  /// Guards against two celebration checks racing into a double-push (e.g.
  /// the mount-time check and a realtime event arriving within the same
  /// frame, or a realtime event firing while a notification tap is already
  /// showing the page). [checkForPendingWinnerAndCelebrate] awaits the full
  /// push-until-popped lifecycle, so this stays true for as long as the
  /// celebration page is actually on screen, not just during its initial
  /// network check.
  bool _celebrationCheckInFlight = false;

  static const _pages = [UserHomePage(), MyGiveawaysPage(), SettingsPage()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForCelebration());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted && getIt.isRegistered<AdService>()) {
        unawaited(getIt<AdService>().startUserSession(ModalRoute.of(context)));
      }
    });

    // Routing (deciding *where* a tap should navigate) is shared with
    // NotificationsPage's in-app tap handling -- see
    // shared/utils/notification_routing.dart -- so there is exactly one
    // implementation of "what does this notification type mean."
    _notificationTapSub = getIt<NotificationService>().onNotificationTapped.listen((data) {
      final currentContext = context;
      if (currentContext.mounted) routeNotificationTap(currentContext, data);
    });

    _subscribeToWinnerNotifications();
  }

  /// Part 4/6: reacts immediately (no restart, no navigate-away-and-back,
  /// no manual refresh) when this user becomes a winner while the app is
  /// already open, by listening for the same `winner_announcement`
  /// `notifications` row `fn_select_winner` already writes -- no new
  /// backend concept, no duplicate winner-detection path. Scoped to
  /// exactly this user's own notifications (RLS -- `notifications_
  /// select_own` -- remains the actual security boundary regardless of this
  /// filter). [checkForPendingWinnerAndCelebrate]'s own server-authoritative
  /// `celebration_acknowledged_at` read is still what guarantees the
  /// celebration fires exactly once; this subscription only decides *when*
  /// to ask.
  Future<void> _subscribeToWinnerNotifications() async {
    final userId = await getIt<SecureStorageService>().cachedUserId;
    if (userId == null || !mounted) return;

    final client = getIt<SupabaseClient>();
    _winnerNotificationChannel = client
        .channel('user-home-winner-notifications-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (payload.newRecord['type'] == 'winner_announcement') {
              _checkForCelebration();
            }
          },
        )
        .subscribe();
  }

  Future<void> _checkForCelebration() async {
    if (_celebrationCheckInFlight || !context.mounted) return;
    _celebrationCheckInFlight = true;
    final ads = getIt.isRegistered<AdService>() ? getIt<AdService>() : null;
    if (ads != null) ads.frequency.criticalFlows++;
    try {
      await checkForPendingWinnerAndCelebrate(context);
    } finally {
      if (ads != null) ads.frequency.criticalFlows--;
      _celebrationCheckInFlight = false;
    }
  }

  @override
  void dispose() {
    if (getIt.isRegistered<AdService>()) getIt<AdService>().endUserSession();
    _notificationTapSub?.cancel();
    final channel = _winnerNotificationChannel;
    if (channel != null) getIt<SupabaseClient>().removeChannel(channel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return UserTabScaffold(
      body: IndexedStack(index: _index, children: _pages),
      banner: getIt.isRegistered<AdService>()
          ? AdaptiveAdBanner(ads: getIt<AdService>())
          : const SizedBox.shrink(),
      navigation: AppBottomNav(
        docked: true,
        selectedIndex: _index,
        onTabSelected: (i) => setState(() => _index = i),
        items: [
          AppBottomNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            semanticLabel: l10n.navHome,
          ),
          AppBottomNavItem(
            icon: Icons.card_giftcard_outlined,
            activeIcon: Icons.card_giftcard_rounded,
            semanticLabel: l10n.myGiveawaysTitle,
          ),
          AppBottomNavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
            semanticLabel: l10n.settingsTitle,
          ),
        ],
      ),
    );
  }
}
