import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/notification_service.dart';
import '../../../services/secure_storage_service.dart';
import '../../../shared/repositories/winner_repository.dart';
import '../../my_giveaways/presentation/my_giveaways_page.dart';
import '../../settings/presentation/settings_page.dart';
import '../../winner_celebration/presentation/winner_celebration_page.dart';
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
  StreamSubscription<void>? _notificationTapSub;

  static const _pages = [UserHomePage(), MyGiveawaysPage(), SettingsPage()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForPendingWinner());

    // A tapped notification is never trusted for *what* happened -- it's
    // only a "go re-check the server" nudge (see NotificationService doc
    // comment), so it re-runs the exact same server-authoritative check as
    // the launch path above.
    _notificationTapSub = getIt<NotificationService>().onNotificationTapped.listen(
      (_) => _checkForPendingWinner(),
    );
  }

  @override
  void dispose() {
    _notificationTapSub?.cancel();
    super.dispose();
  }

  /// Checked on shell mount (app launch / role re-entry) and whenever a
  /// notification is tapped -- the server-side `celebration_acknowledged_at`
  /// gate is what actually guarantees exactly-once, this is just when we ask.
  Future<void> _checkForPendingWinner() async {
    final userId = await getIt<SecureStorageService>().cachedUserId;
    if (userId == null) return;

    final result = await getIt<WinnerRepository>().getMyPendingWinner(userId);
    final winner = result.fold((_) => null, (w) => w);
    if (winner == null || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => WinnerCelebrationPage(winner: winner),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      backgroundColor: AppColors.surface,
      body: IndexedStack(index: _index, children: _pages),
      bottomBar: GlassTabBar.bottom(
        selectedIndex: _index,
        onTabSelected: (i) => setState(() => _index = i),
        indicatorColor: AppColors.primary,
        selectedIconColor: AppColors.primary,
        selectedLabelColor: AppColors.primary,
        unselectedIconColor: AppColors.outline,
        unselectedLabelColor: AppColors.outline,
        glowOpacity: 0.35,
        tabs: const [
          GlassTab(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          GlassTab(
            icon: Icon(Icons.card_giftcard_outlined),
            activeIcon: Icon(Icons.card_giftcard_rounded),
            label: 'My Giveaways',
          ),
          GlassTab(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
