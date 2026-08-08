import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';

enum CreateGiveawayStatus { idle, submitting, success, error }

class CreateGiveawayState extends Equatable {
  const CreateGiveawayState({this.status = CreateGiveawayStatus.idle, this.failure});

  final CreateGiveawayStatus status;
  final Failure? failure;

  CreateGiveawayState copyWith({CreateGiveawayStatus? status, Failure? failure}) {
    return CreateGiveawayState(status: status ?? this.status, failure: failure);
  }

  @override
  List<Object?> get props => [status, failure];
}
