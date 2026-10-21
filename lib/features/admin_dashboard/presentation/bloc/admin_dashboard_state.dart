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
    this.activeCampaigns = const [],
    this.upcomingCampaigns = const [],
    this.endedCampaigns = const [],
    this.failure,
  });

  final AdminDashboardStatus status;
  final int activeCount;
  final int totalParticipants;
  final int finishedCount;
  final int winnersSelectedCount;

  /// All of this admin's own active giveaways -- rendered as one card each
  /// (implementation-plan.md's Admin Dashboard section). Now that there is
  /// no standalone Giveaways list, this is the only place an admin reaches
  /// "View Analysis" for a specific campaign, so it must show every active
  /// campaign, not just the first.
  final List<Giveaway> activeCampaigns;
  final List<Giveaway> upcomingCampaigns;

  /// A giveaway ending (a winner selected, manually or automatically) must
  /// never make it disappear from the admin's app -- this is the historical/
  /// ended counterpart to [activeCampaigns], rendered as its own section so
  /// the giveaway, its winner(s), and its analytics all stay reachable.
  final List<Giveaway> endedCampaigns;
  final Failure? failure;

  AdminDashboardState copyWith({
    AdminDashboardStatus? status,
    int? activeCount,
    int? totalParticipants,
    int? finishedCount,
    int? winnersSelectedCount,
    List<Giveaway>? activeCampaigns,
    List<Giveaway>? upcomingCampaigns,
    List<Giveaway>? endedCampaigns,
    Failure? failure,
  }) {
    return AdminDashboardState(
      status: status ?? this.status,
      activeCount: activeCount ?? this.activeCount,
      totalParticipants: totalParticipants ?? this.totalParticipants,
      finishedCount: finishedCount ?? this.finishedCount,
      winnersSelectedCount: winnersSelectedCount ?? this.winnersSelectedCount,
      activeCampaigns: activeCampaigns ?? this.activeCampaigns,
      upcomingCampaigns: upcomingCampaigns ?? this.upcomingCampaigns,
      endedCampaigns: endedCampaigns ?? this.endedCampaigns,
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
    activeCampaigns,
    upcomingCampaigns,
    endedCampaigns,
    failure,
  ];
}
