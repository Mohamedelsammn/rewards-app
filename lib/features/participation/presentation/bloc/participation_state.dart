import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';

/// The participation flow's stages: check local identity -> Registration
/// (if needed) -> create-participation -> hand off to Scratch Card. V1 has
/// no advertisement system, so there is no ad-gating stage here at all --
/// the flow goes straight from identity to server-side participation
/// creation (implementation-plan.md §3, updated for the no-AdMob V1 flow).
enum ParticipationStep {
  checkingIdentity,
  needsRegistration,
  submittingRegistration,
  creatingParticipation,
  success,
  failure,
}

class ParticipationState extends Equatable {
  const ParticipationState({
    this.step = ParticipationStep.checkingIdentity,
    this.participationId,
    this.participationNumber,
    this.failure,
  });

  final ParticipationStep step;
  final String? participationId;
  final int? participationNumber;
  final Failure? failure;

  ParticipationState copyWith({
    ParticipationStep? step,
    String? participationId,
    int? participationNumber,
    Failure? failure,
  }) {
    return ParticipationState(
      step: step ?? this.step,
      participationId: participationId ?? this.participationId,
      participationNumber: participationNumber ?? this.participationNumber,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [step, participationId, participationNumber, failure];
}
