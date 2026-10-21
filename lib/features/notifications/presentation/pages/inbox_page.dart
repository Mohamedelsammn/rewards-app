import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/paged_list_state.dart';
import '../../../../core/widgets/headers.dart';
import '../../../../core/widgets/paged_list_view.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/notification_entities.dart';
import '../bloc/inbox_cubit.dart';
import '../bloc/unread_count_cubit.dart';
import '../notification_navigation.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => InboxCubit(sl(), context.read<UnreadCountCubit>())..refresh(),
    child: const _InboxView(),
  );
}

class _InboxView extends StatefulWidget {
  const _InboxView();

  @override
  State<_InboxView> createState() => _InboxViewState();
}

class _InboxViewState extends State<_InboxView> {
  StreamSubscription<void>? _pushes;

  @override
  void initState() {
    super.initState();
    // A foreground push is a hint: reload the inbox.
    _pushes = sl<PushNotificationService>().received.listen((_) {
      if (mounted) context.read<InboxCubit>().refresh();
    });
  }

  @override
  void dispose() {
    _pushes?.cancel();
    super.dispose();
  }

  Future<void> _markAll() async {
    try {
      await context.read<InboxCubit>().markAllRead();
    } catch (error) {
      if (mounted) showErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<InboxCubit>();
    final unread = context.watch<UnreadCountCubit>().state;
    return Scaffold(
      backgroundColor: AppColors.surface,
      // The circles sit outside SafeArea so they fade off-screen instead of
      // being cut along the safe-area edge.
      body: Stack(
        children: [
          const PositionedDirectional(top: -80, end: -95, child: _DecorativeCircle(230)),
          const PositionedDirectional(bottom: -105, start: -110, child: _DecorativeCircle(240)),
          SafeArea(
            child: BlocBuilder<InboxCubit, PagedListState<AppNotification, void>>(
              builder: (context, state) => PagedListView<AppNotification, void>(
                state: state,
                onRefresh: cubit.refresh,
                onLoadMore: cubit.loadMore,
                emptyMessage: l10n.notificationsEmpty,
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                header: [
                  SecondaryHeader(
                    title: l10n.notificationsTitle,
                    subtitle: '',
                    action: unread > 0
                        ? IconButton(
                            tooltip: l10n.notificationsMarkAll,
                            onPressed: _markAll,
                            icon: const Icon(Icons.done_all_rounded, color: AppColors.violet),
                          )
                        : null,
                  ),
                  const SizedBox(height: 20),
                ],
                itemBuilder: (context, item) => _NotificationCard(
                  item: item,
                  onTap: () {
                    cubit.markRead(item);
                    openNotification(context, item);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle(this.size);

  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [Color(0xffece7ff), Color(0x00ece7ff)]),
      ),
    ),
  );
}

String notificationAge(BuildContext context, DateTime? createdAt) {
  final l10n = context.l10n;
  if (createdAt == null) return l10n.notifEarlier;
  final age = DateTime.now().difference(createdAt);
  if (age.inMinutes < 1) return l10n.notifNow;
  if (age.inHours < 1) return l10n.notifMinutes(age.inMinutes);
  if (age.inDays < 1) return l10n.notifHours(age.inHours);
  if (age.inDays < 2) return l10n.notifYesterday;
  return l10n.notifEarlier;
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(25),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.read ? Colors.white : const Color(0xfff4f1ff),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(color: Color(0x147661ae), blurRadius: 22, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xffcbbaff), Color(0xffeee8ff)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(_icon(item.type), color: AppColors.violet, size: 40),
              ),
              const PositionedDirectional(
                top: -8,
                start: -7,
                child: Icon(Icons.auto_awesome, color: AppColors.violet, size: 15),
              ),
              const PositionedDirectional(
                bottom: -7,
                end: -6,
                child: Icon(Icons.auto_awesome, color: Color(0xffffce4d), size: 17),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.of(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.body.of(context),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xffeeeaff),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  notificationAge(context, item.createdAt),
                  style: const TextStyle(color: AppColors.violet, fontSize: 11),
                ),
              ),
              const SizedBox(height: 8),
              const CircleArrow(),
            ],
          ),
        ],
      ),
    ),
  );

  IconData _icon(NotificationType type) => switch (type) {
    NotificationType.orderStatus => Icons.local_shipping_rounded,
    NotificationType.winnerSelected => Icons.emoji_events_rounded,
    NotificationType.giveawayResult => Icons.card_giftcard_rounded,
    _ => Icons.notifications_rounded,
  };
}
