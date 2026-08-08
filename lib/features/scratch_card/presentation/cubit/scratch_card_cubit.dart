import 'package:flutter_bloc/flutter_bloc.dart';

import 'scratch_card_state.dart';

/// Presentation-only: tracks scratchPercent/isRevealed and nothing else.
/// The participation number is already server-persisted before this widget
/// ever renders (implementation-plan.md §20) -- this Cubit must never call
/// a repository or touch the network.
class ScratchCardCubit extends Cubit<ScratchCardState> {
  ScratchCardCubit() : super(const ScratchCardState());

  static const double completionThreshold = 0.6;

  void updateProgress(double percent) {
    if (state.isRevealed) return;
    final clamped = percent.clamp(0.0, 1.0);
    if (clamped >= completionThreshold) {
      emit(state.copyWith(scratchPercent: 1, isRevealed: true));
    } else {
      emit(state.copyWith(scratchPercent: clamped));
    }
  }

  void revealImmediately() {
    if (!state.isRevealed) emit(state.copyWith(scratchPercent: 1, isRevealed: true));
  }
}
