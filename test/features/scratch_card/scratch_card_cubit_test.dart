import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/features/scratch_card/presentation/cubit/scratch_card_cubit.dart';
import 'package:rewardsapp/features/scratch_card/presentation/cubit/scratch_card_state.dart';

void main() {
  group('ScratchCardCubit', () {
    blocTest<ScratchCardCubit, ScratchCardState>(
      'stays unrevealed just below the 60% threshold',
      build: ScratchCardCubit.new,
      act: (cubit) => cubit.updateProgress(0.59),
      expect: () => [const ScratchCardState(scratchPercent: 0.59, isRevealed: false)],
    );

    blocTest<ScratchCardCubit, ScratchCardState>(
      'auto-completes exactly at the 60% threshold',
      build: ScratchCardCubit.new,
      act: (cubit) => cubit.updateProgress(0.60),
      expect: () => [const ScratchCardState(scratchPercent: 1, isRevealed: true)],
    );

    blocTest<ScratchCardCubit, ScratchCardState>(
      'auto-completes above the 60% threshold',
      build: ScratchCardCubit.new,
      act: (cubit) => cubit.updateProgress(0.85),
      expect: () => [const ScratchCardState(scratchPercent: 1, isRevealed: true)],
    );

    blocTest<ScratchCardCubit, ScratchCardState>(
      'ignores further updates once revealed',
      build: ScratchCardCubit.new,
      act: (cubit) {
        cubit.updateProgress(0.65);
        cubit.updateProgress(0.10);
      },
      expect: () => [const ScratchCardState(scratchPercent: 1, isRevealed: true)],
    );

    blocTest<ScratchCardCubit, ScratchCardState>(
      'revealImmediately forces the revealed state',
      build: ScratchCardCubit.new,
      act: (cubit) => cubit.revealImmediately(),
      expect: () => [const ScratchCardState(scratchPercent: 1, isRevealed: true)],
    );
  });
}
