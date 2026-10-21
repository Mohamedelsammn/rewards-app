import 'package:equatable/equatable.dart';

import '../../../core/localization/localized_text.dart';
import '../../../core/utils/cursor_page.dart';

enum NotificationType { orderStatus, winnerSelected, giveawayResult, announcement, other }

NotificationType notificationTypeFrom(String? value) => switch (value) {
  'ORDER_STATUS' => NotificationType.orderStatus,
  'WINNER_SELECTED' => NotificationType.winnerSelected,
  'GIVEAWAY_RESULT' => NotificationType.giveawayResult,
  'ANNOUNCEMENT' => NotificationType.announcement,
  _ => NotificationType.other,
};

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.read = false,
    this.createdAt,
  });

  final String id;
  final NotificationType type;
  final LocalizedText title;
  final LocalizedText body;
  final Map<String, String> data;
  final bool read;
  final DateTime? createdAt;

  AppNotification markedRead() => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    data: data,
    read: true,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [id, type, read, createdAt];
}

class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    this.orders = true,
    this.giveaways = true,
    this.announcements = false,
  });

  final bool orders;
  final bool giveaways;
  final bool announcements;

  NotificationPreferences copyWith({bool? orders, bool? giveaways, bool? announcements}) =>
      NotificationPreferences(
        orders: orders ?? this.orders,
        giveaways: giveaways ?? this.giveaways,
        announcements: announcements ?? this.announcements,
      );

  @override
  List<Object?> get props => [orders, giveaways, announcements];
}

abstract interface class NotificationsRepository {
  Future<CursorPage<AppNotification>> notifications({bool unreadOnly = false, String? cursor});

  Future<int> unreadCount();

  Future<AppNotification> notification(String id);

  Future<void> markRead(String id);

  Future<void> markAllRead();

  Future<NotificationPreferences> preferences();

  Future<NotificationPreferences> updatePreferences(NotificationPreferences preferences);

  Future<void> registerDevice({
    required String installationId,
    required String? fcmToken,
    required String platform,
    required String appVersion,
    required String language,
  });

  Future<void> unregisterDevice(String installationId);
}
