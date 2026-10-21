import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../domain/notification_entities.dart';

/// Where a notification (inbox item or push tap) leads, from its `type` and
/// `data` (docs/FLUTTER_INTEGRATION-5.md §4 "Notification type").
/// Returns null when the notification has no dedicated screen.
String? notificationTarget(NotificationType type, Map<String, String> data) {
  final orderId = data['orderId'];
  final giveawayId = data['giveawayId'];
  return switch (type) {
    NotificationType.orderStatus when orderId != null && orderId.isNotEmpty => Routes.order(
      orderId,
    ),
    // The celebration itself comes from /me/winnings/pending-celebration.
    NotificationType.winnerSelected => Routes.myGiveaways,
    NotificationType.giveawayResult when giveawayId != null && giveawayId.isNotEmpty =>
      Routes.giveaway(giveawayId),
    _ => null,
  };
}

/// Push taps carry the raw FCM data map; `type` mirrors the inbox type.
String? pushTarget(Map<String, String> data) {
  final target = notificationTarget(notificationTypeFrom(data['type']), data);
  if (target != null) return target;
  final id = data['notificationId'];
  return id != null && id.isNotEmpty ? Routes.notification(id) : Routes.notifications;
}

void openNotification(BuildContext context, AppNotification notification) {
  final target = notificationTarget(notification.type, notification.data);
  context.push(
    target ?? Routes.notification(notification.id),
    extra: target == null ? notification : null,
  );
}
