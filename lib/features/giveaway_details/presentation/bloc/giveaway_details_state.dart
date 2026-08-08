import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../shared/models/giveaway.dart';
import '../../../../shared/models/giveaway_requirement.dart';

enum GiveawayDetailsStatus { loading, loaded, error }

class GiveawayDetailsState extends Equatable {
  const GiveawayDetailsState({
    this.status = GiveawayDetailsStatus.loading,
    this.giveaway,
    this.requirements = const [],
    this.alreadyJoined = false,
    this.myParticipationNumber,
    this.failure,
  });

  final GiveawayDetailsStatus status;
  final Giveaway? giveaway;
  final List<GiveawayRequirement> requirements;
  final bool alreadyJoined;
  final int? myParticipationNumber;
  final Failure? failure;

  GiveawayDetailsState copyWith({
    GiveawayDetailsStatus? status,
    Giveaway? giveaway,
    List<GiveawayRequirement>? requirements,
    bool? alreadyJoined,
    int? myParticipationNumber,
    Failure? failure,
  }) {
    return GiveawayDetailsState(
      status: status ?? this.status,
      giveaway: giveaway ?? this.giveaway,
      requirements: requirements ?? this.requirements,
      alreadyJoined: alreadyJoined ?? this.alreadyJoined,
      myParticipationNumber: myParticipationNumber ?? this.myParticipationNumber,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    giveaway,
    requirements,
    alreadyJoined,
    myParticipationNumber,
    failure,
  ];
}
