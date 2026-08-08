import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../shared/models/giveaway.dart';

enum AdminDashboardStatus { loading, loaded, error }

class AdminDashboardState extends Equatable {
  const AdminDashboardState({
    this.status = AdminDashboardStatus.loading,
    this.activeCount = 0,
    this.totalParticipants = 0,
    this.finishedCount = 0,
    this.winnersSelectedCount = 0,
    this.activeCampaign,
    this.failure,
  });

  final AdminDashboardStatus status;
  final int activeCount;
  final int totalParticipants;
  final int finishedCount;
  final int winnersSelectedCount;
  final Giveaway? activeCampaign;
  final Failure? failure;

  AdminDashboardState copyWith({
    AdminDashboardStatus? status,
    int? activeCount,
    int? totalParticipants,
    int? finishedCount,
    int? winnersSelectedCount,
    Giveaway? activeCampaign,
    Failure? failure,
  }) {
    return AdminDashboardState(
      status: status ?? this.status,
      activeCount: activeCount ?? this.activeCount,
      totalParticipants: totalParticipants ?? this.totalParticipants,
      finishedCount: finishedCount ?? this.finishedCount,
      winnersSelectedCount: winnersSelectedCount ?? this.winnersSelectedCount,
      activeCampaign: activeCampaign ?? this.activeCampaign,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    activeCount,
    totalParticipants,
    finishedCount,
    winnersSelectedCount,
    activeCampaign,
    failure,
  ];
}
