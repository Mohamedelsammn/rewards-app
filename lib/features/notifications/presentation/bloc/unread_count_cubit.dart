import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/notification_entities.dart';

/// Badge count for the Home and Wallet bells and the Profile row.
class UnreadCountCubit extends Cubit<int> {
  UnreadCountCubit(this._repository) : super(0);

  final NotificationsRepository _repository;

  Future<void> refresh() async {
    try {
      emit(await _repository.unreadCount());
    } catch (_) {
      // Keep the last known count; badges are not critical.
    }
  }

  void markedOneRead() {
    if (state > 0) emit(state - 1);
  }

  void clear() => emit(0);
}
