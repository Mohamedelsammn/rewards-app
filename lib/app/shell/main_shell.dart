import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/services/ads/ads_manager.dart';
import '../../core/services/push_notification_service.dart';
import '../../features/app_config/presentation/app_config_cubit.dart';
import '../../features/giveaways/presentation/celebration/celebration_coordinator.dart';
import '../../features/notifications/presentation/bloc/unread_count_cubit.dart';
import '../../features/notifications/presentation/notification_navigation.dart';
import '../../features/wallet/presentation/bloc/wallet_cubit.dart';
import '../di/injection_container.dart';
import 'app_bottom_bar.dart';

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
    // Signed in: initialize ads (consent first) and preload the placements.
    if (sl.isRegistered<AdsManager>()) unawaited(sl<AdsManager>().warmUp());
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
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: AppBottomBar(
        currentIndex: widget.navigationShell.currentIndex,
        onSelect: _go,
      ),
    );
  }

  void _go(int index) => widget.navigationShell.goBranch(
    index,
    initialLocation: index == widget.navigationShell.currentIndex,
  );
}
