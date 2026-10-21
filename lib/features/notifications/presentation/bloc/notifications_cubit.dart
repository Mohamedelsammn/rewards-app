import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/repositories/notification_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState());

  final NotificationRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: NotificationsStatus.loading));
    final result = await _repository.getMyNotifications();
    result.fold(
      (failure) => emit(state.copyWith(status: NotificationsStatus.error, failure: failure)),
      (notifications) => emit(
        state.copyWith(
          status: notifications.isEmpty ? NotificationsStatus.empty : NotificationsStatus.loaded,
          notifications: notifications,
        ),
      ),
    );
  }

  /// Marks one notification read, optimistically, so the tapped item's dot
  /// disappears immediately instead of waiting for a round-trip. Reverts
  /// silently on failure (rare -- own-row RLS update) rather than surfacing
  /// an error for a non-critical background write.
  Future<void> markAsRead(String notificationId) async {
    final index = state.notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1 || state.notifications[index].isRead) return;

    final updated = [...state.notifications];
    updated[index] = updated[index].copyWith(isRead: true);
    emit(state.copyWith(notifications: updated));

    final result = await _repository.markAsRead(notificationId);
    if (result.isFailure) {
      final reverted = [...state.notifications];
      reverted[index] = reverted[index].copyWith(isRead: false);
      emit(state.copyWith(notifications: reverted));
    }
  }

  Future<void> markAllAsRead() async {
    if (state.notifications.every((n) => n.isRead)) return;
    final previous = state.notifications;
    emit(state.copyWith(notifications: [for (final n in previous) n.copyWith(isRead: true)]));

    final result = await _repository.markAllAsRead();
    if (result.isFailure) {
      emit(state.copyWith(notifications: previous));
    }
  }
}
