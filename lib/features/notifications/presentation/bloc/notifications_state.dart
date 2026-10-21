import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../shared/models/notification_item.dart';

enum NotificationsStatus { loading, loaded, empty, error }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.loading,
    this.notifications = const [],
    this.failure,
  });

  final NotificationsStatus status;
  final List<NotificationItem> notifications;
  final Failure? failure;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationItem>? notifications,
    Failure? failure,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [status, notifications, failure];
}
