import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/localization/l10n.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../features/app_config/presentation/app_config_cubit.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/bloc/session_cubit.dart';
import '../../features/giveaways/presentation/celebration/celebration_coordinator.dart';
import '../../features/notifications/presentation/bloc/unread_count_cubit.dart';
import '../../features/notifications/presentation/notification_navigation.dart';
import '../../features/profile/presentation/widgets/character_avatar.dart';
import '../../features/wallet/presentation/bloc/wallet_cubit.dart';
import '../di/injection_container.dart';

/// Signed-in shell: the four tabs with the redesign's bottom bar. Also owns
/// the signed-in lifecycle work (refresh on resume, push, celebrations).
class MainShell extends StatefulWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  final _push = sl<PushNotificationService>();
  final _celebrations = sl<CelebrationCoordinator>();
  final _subscriptions = <StreamSubscription<Object?>>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscriptions
      ..add(_push.taps.listen(_openPush))
      ..add(
        _push.received.listen((_) {
          if (!mounted) return;
          context.read<UnreadCountCubit>().refresh();
          _checkCelebrations();
        }),
      );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refresh();
      _push.registerForSignedInUser(sl<LocaleController>().value.languageCode);
      final initial = _push.takeInitialTap();
      if (initial != null) _openPush(initial);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    context.read<AppConfigCubit>().load(silent: true);
    _refresh();
  }

  void _refresh() {
    context.read<WalletCubit>().load();
    context.read<UnreadCountCubit>().refresh();
    _checkCelebrations();
  }

  void _checkCelebrations() => _celebrations.check(() => context);

  void _openPush(Map<String, String> data) {
    if (!mounted) return;
    context.read<UnreadCountCubit>().refresh();
    final target = pushTarget(data);
    if (target != null) context.push(target);
    if (data['type'] == 'WINNER_SELECTED') _checkCelebrations();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = widget.navigationShell.currentIndex;
    final user = context.select<SessionCubit, AppUser?>((cubit) => cubit.state.user);
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 80,
          decoration: const BoxDecoration(
            color: AppColors.navBackground,
            border: Border(top: BorderSide(color: AppColors.navBorder)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavTab(
                label: l10n.navHome,
                selected: current == 0,
                icon: current == 0 ? Icons.home_rounded : LucideIcons.house,
                onTap: () => _go(0),
              ),
              _NavTab(
                label: l10n.navCategories,
                selected: current == 1,
                icon: current == 1 ? Icons.grid_view_rounded : AppIcons.categories,
                iconSize: 28,
                onTap: () => _go(1),
              ),
              _NavTab(
                label: l10n.navWallet,
                selected: current == 2,
                icon: current == 2 ? Icons.wallet_rounded : LucideIcons.wallet,
                onTap: () => _go(2),
              ),
              _NavTab(
                label: l10n.navProfile,
                selected: current == 3,
                onTap: () => _go(3),
                avatar: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.avatarRing,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CharacterImage(
                    avatarId: user?.avatarId,
                    imageUrl: user?.avatarImageUrl,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _go(int index) => widget.navigationShell.goBranch(
    index,
    initialLocation: index == widget.navigationShell.currentIndex,
  );
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.iconSize = 27,
    this.avatar,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final double iconSize;
  final Widget? avatar;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.violet : AppColors.muted;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              avatar ??
                  SizedBox(
                    height: 40,
                    child: Center(
                      child: Icon(icon, color: color, size: iconSize),
                    ),
                  ),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
