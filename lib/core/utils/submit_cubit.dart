import 'package:flutter_bloc/flutter_bloc.dart';

import 'submit_state.dart';

/// Runs one user-triggered request at a time and exposes its [SubmitState].
/// Used by simple forms (save profile, change password, delete account…).
class SubmitCubit<T> extends Cubit<SubmitState<T>> {
  SubmitCubit() : super(SubmitState<T>());

  Future<void> run(Future<T> Function() action) async {
    if (state.busy) return;
    emit(state.toBusy());
    try {
      final result = await action();
      if (!isClosed) emit(SubmitState<T>(status: SubmitStatus.success, result: result));
    } catch (error) {
      if (!isClosed) emit(SubmitState<T>(status: SubmitStatus.failure, error: error));
    }
  }
}
