import 'package:equatable/equatable.dart';

class ScratchCardState extends Equatable {
  const ScratchCardState({this.scratchPercent = 0, this.isRevealed = false});

  final double scratchPercent;
  final bool isRevealed;

  ScratchCardState copyWith({double? scratchPercent, bool? isRevealed}) {
    return ScratchCardState(
      scratchPercent: scratchPercent ?? this.scratchPercent,
      isRevealed: isRevealed ?? this.isRevealed,
    );
  }

  @override
  List<Object?> get props => [scratchPercent, isRevealed];
}
