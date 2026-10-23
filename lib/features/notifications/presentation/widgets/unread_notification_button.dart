import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../bloc/unread_count_cubit.dart';

/// Bell with the unread badge from `GET /notifications/unread-count`.
class UnreadNotificationButton extends StatelessWidget {
  const UnreadNotificationButton({this.filled = false, super.key});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<UnreadCountCubit>().state;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: context.l10n.notificationsTooltip,
          onPressed: () => context.push(Routes.notifications),
          // The filled (Home header) variant uses a solid bell, as in the reference.
          icon: Icon(filled ? Icons.notifications_rounded : AppIcons.bell),
          style: IconButton.styleFrom(
            backgroundColor: filled ? Colors.white : Colors.transparent,
            foregroundColor: filled ? AppColors.violet : AppColors.ink,
          ),
        ),
        if (unread > 0)
          PositionedDirectional(
            top: 0,
            end: 0,
            child: ExcludeSemantics(child: UnreadBadge(count: unread, size: 18, fontSize: 9)),
          ),
      ],
    );
  }
}

class UnreadBadge extends StatelessWidget {
  const UnreadBadge({
    required this.count,
    this.size = 22,
    this.fontSize = 11,
    this.color = AppColors.badge,
    super.key,
  });

  final int count;
  final double size;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(minWidth: size, minHeight: size),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    alignment: Alignment.center,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Text(
      count > 99 ? '99+' : '$count',
      style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w800),
    ),
  );
}
