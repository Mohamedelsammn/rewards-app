import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../shared/models/giveaway.dart';
import '../../../../shared/models/giveaway_requirement.dart';

enum GiveawayDetailsStatus { loading, loaded, error }

enum ParticipationCheckStatus { initial, loading, joined, notJoined, error }

class GiveawayDetailsState extends Equatable {
  const GiveawayDetailsState({
    this.status = GiveawayDetailsStatus.loading,
    this.giveaway,
    this.requirements = const [],
    this.alreadyJoined = false,
    this.participationCheckStatus = ParticipationCheckStatus.initial,
    this.myParticipationNumber,
    this.rewardedFrameUnlocked = false,
    this.failure,
    this.clockRevision = 0,
  });

  final GiveawayDetailsStatus status;
  final Giveaway? giveaway;
  final List<GiveawayRequirement> requirements;
  final bool alreadyJoined;
  final ParticipationCheckStatus participationCheckStatus;
  final int? myParticipationNumber;
  final bool rewardedFrameUnlocked;
  final Failure? failure;
  final int clockRevision;

  GiveawayDetailsState copyWith({
    GiveawayDetailsStatus? status,
    Giveaway? giveaway,
    List<GiveawayRequirement>? requirements,
    bool? alreadyJoined,
    ParticipationCheckStatus? participationCheckStatus,
    int? myParticipationNumber,
    bool? rewardedFrameUnlocked,
    Failure? failure,
    int? clockRevision,
  }) {
    return GiveawayDetailsState(
      status: status ?? this.status,
      giveaway: giveaway ?? this.giveaway,
      requirements: requirements ?? this.requirements,
      alreadyJoined: alreadyJoined ?? this.alreadyJoined,
      participationCheckStatus: participationCheckStatus ?? this.participationCheckStatus,
      myParticipationNumber: myParticipationNumber ?? this.myParticipationNumber,
      rewardedFrameUnlocked: rewardedFrameUnlocked ?? this.rewardedFrameUnlocked,
      failure: failure,
      clockRevision: clockRevision ?? this.clockRevision,
    );
  }

  @override
  List<Object?> get props => [
    status,
    giveaway,
    requirements,
    alreadyJoined,
    participationCheckStatus,
    myParticipationNumber,
    rewardedFrameUnlocked,
    failure,
    clockRevision,
  ];
}
