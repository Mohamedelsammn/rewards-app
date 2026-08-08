import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../shared/models/giveaway.dart';

enum AdminGiveawaysStatus { loading, loaded, error }

class AdminGiveawaysState extends Equatable {
  const AdminGiveawaysState({
    this.status = AdminGiveawaysStatus.loading,
    this.giveaways = const [],
    this.failure,
  });

  final AdminGiveawaysStatus status;
  final List<Giveaway> giveaways;
  final Failure? failure;

  AdminGiveawaysState copyWith({
    AdminGiveawaysStatus? status,
    List<Giveaway>? giveaways,
    Failure? failure,
  }) {
    return AdminGiveawaysState(
      status: status ?? this.status,
      giveaways: giveaways ?? this.giveaways,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [status, giveaways, failure];
}
