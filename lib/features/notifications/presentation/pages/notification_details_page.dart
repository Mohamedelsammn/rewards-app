import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/headers.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/notification_entities.dart';
import '../bloc/unread_count_cubit.dart';

/// Announcement details. Opened from the inbox (with [initial]) or from a
/// push tap (loaded with `GET /notifications/:id`), and marked read.
class NotificationDetailsPage extends StatefulWidget {
  const NotificationDetailsPage({required this.id, this.initial, super.key});

  final String id;
  final AppNotification? initial;

  @override
  State<NotificationDetailsPage> createState() => _NotificationDetailsPageState();
}

class _NotificationDetailsPageState extends State<NotificationDetailsPage> {
  final _repository = sl<NotificationsRepository>();
  late Future<AppNotification> _notification = _load();

  Future<AppNotification> _load() async {
    final unread = context.read<UnreadCountCubit>();
    final notification = widget.initial ?? await _repository.notification(widget.id);
    if (!notification.read) {
      try {
        await _repository.markRead(notification.id);
        await unread.refresh();
      } catch (_) {
        // Reading still works; the badge refreshes on resume.
      }
    }
    return notification;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: FutureBuilder<AppNotification>(
        future: _notification,
        builder: (context, snapshot) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Align(alignment: AlignmentDirectional.centerStart, child: CircleBackButton()),
            const SizedBox(height: 28),
            if (snapshot.hasError)
              ErrorStateView(
                error: snapshot.error!,
                onRetry: () => setState(() => _notification = _load()),
              )
            else if (snapshot.data case final notification?) ...[
              Text(
                notification.title.of(context),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (notification.createdAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  Formatters.dateTime(context, notification.createdAt!),
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                notification.body.of(context),
                style: const TextStyle(color: AppColors.muted, fontSize: 17, height: 1.5),
              ),
            ] else
              // Title, date and body lines of the notification.
              const Skeleton(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: 260, height: 26),
                    SizedBox(height: 10),
                    SkeletonLine(width: 170, height: 26),
                    SizedBox(height: 14),
                    SkeletonLine(width: 120, height: 12),
                    SizedBox(height: 20),
                    SkeletonLine(width: 320, height: 15),
                    SizedBox(height: 10),
                    SkeletonLine(width: 300, height: 15),
                    SizedBox(height: 10),
                    SkeletonLine(width: 210, height: 15),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
