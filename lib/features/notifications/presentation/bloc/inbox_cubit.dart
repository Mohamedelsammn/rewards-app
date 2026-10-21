import '../../../../core/utils/cursor_page.dart';
import '../../../../core/utils/paged_cubit.dart';
import '../../domain/notification_entities.dart';
import 'unread_count_cubit.dart';

/// `GET /notifications` with optimistic read state.
class InboxCubit extends PagedCubit<AppNotification, void> {
  InboxCubit(this._repository, this._unread) : super(null);

  final NotificationsRepository _repository;
  final UnreadCountCubit _unread;

  @override
  Future<CursorPage<AppNotification>> fetch(void filter, String? cursor) =>
      _repository.notifications(cursor: cursor);

  Future<void> markRead(AppNotification notification) async {
    if (notification.read) return;
    emit(
      state.copyWith(
        items: [
          for (final item in state.items) item.id == notification.id ? item.markedRead() : item,
        ],
      ),
    );
    _unread.markedOneRead();
    try {
      await _repository.markRead(notification.id);
    } catch (_) {
      // Idempotent on the server; the next refresh shows the real state.
    }
    await _unread.refresh();
  }

  Future<void> markAllRead() async {
    await _repository.markAllRead();
    emit(state.copyWith(items: [for (final item in state.items) item.markedRead()]));
    _unread.clear();
  }
}
