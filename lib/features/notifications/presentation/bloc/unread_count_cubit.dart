import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/notification_entities.dart';
import '../../../../core/utils/safe_emit.dart';

/// Badge count for the Home and Wallet bells and the Profile row.
class UnreadCountCubit extends Cubit<int> with SafeEmit<int> {
  UnreadCountCubit(this._repository) : super(0);

  final NotificationsRepository _repository;

  /// Bumped by [clear] (sign-out): a count requested for an earlier
  /// session is dropped.
  int _generation = 0;

  Future<void> refresh() async {
    final generation = _generation;
    try {
      final count = await _repository.unreadCount();
      if (!isClosed && generation == _generation) emit(count);
    } catch (_) {
      // Keep the last known count; badges are not critical.
    }
  }

  void markedOneRead() {
    if (state > 0) emit(state - 1);
  }

  void clear() {
    _generation++;
    emit(0);
  }
}
