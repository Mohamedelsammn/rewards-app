import 'package:flutter_bloc/flutter_bloc.dart';

/// Drops states emitted after [Cubit.close]. A screen's cubit closes when
/// the user leaves it, while its requests may still complete (or fail)
/// later; those late results are no longer wanted. Only the "emit after
/// close" case is ignored: every other error still surfaces.
mixin SafeEmit<S> on Cubit<S> {
  @override
  void emit(S state) {
    if (isClosed) return;
    super.emit(state);
  }
}
