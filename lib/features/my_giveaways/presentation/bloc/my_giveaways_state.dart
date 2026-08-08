import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../shared/models/participation.dart';

enum MyGiveawaysStatus { loading, loaded, empty, error }

class MyGiveawaysState extends Equatable {
  const MyGiveawaysState({
    this.status = MyGiveawaysStatus.loading,
    this.participations = const [],
    this.failure,
  });

  final MyGiveawaysStatus status;
  final List<Participation> participations;
  final Failure? failure;

  MyGiveawaysState copyWith({
    MyGiveawaysStatus? status,
    List<Participation>? participations,
    Failure? failure,
  }) {
    return MyGiveawaysState(
      status: status ?? this.status,
      participations: participations ?? this.participations,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [status, participations, failure];
}
