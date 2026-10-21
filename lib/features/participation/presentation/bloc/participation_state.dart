import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';

/// Identity, optional-ad preparation, authoritative entry, then the existing reveal.
enum ParticipationStep {
  checkingIdentity,
  needsRegistration,
  submittingRegistration,
  readyToJoin,
  showingRewardedAd,
  creatingParticipation,
  participationCreated,
  alreadyParticipating,
  success,
  failure,
}

class ParticipationState extends Equatable {
  const ParticipationState({
    this.step = ParticipationStep.checkingIdentity,
    this.participationId,
    this.participationNumber,
    this.rewardedFrameUnlocked = false,
    this.failure,
  });

  final ParticipationStep step;
  final String? participationId;
  final int? participationNumber;
  final bool rewardedFrameUnlocked;
  final Failure? failure;

  ParticipationState copyWith({
    ParticipationStep? step,
    String? participationId,
    int? participationNumber,
    bool? rewardedFrameUnlocked,
    Failure? failure,
  }) {
    return ParticipationState(
      step: step ?? this.step,
      participationId: participationId ?? this.participationId,
      participationNumber: participationNumber ?? this.participationNumber,
      rewardedFrameUnlocked: rewardedFrameUnlocked ?? this.rewardedFrameUnlocked,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [
    step,
    participationId,
    participationNumber,
    rewardedFrameUnlocked,
    failure,
  ];
}
