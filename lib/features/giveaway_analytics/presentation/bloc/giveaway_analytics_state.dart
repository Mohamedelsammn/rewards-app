import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../shared/models/giveaway.dart';
import '../../../../shared/models/winner.dart';

enum GiveawayAnalyticsStatus { loading, loaded, error }

class RecentParticipant extends Equatable {
  const RecentParticipant({
    required this.participationSequence,
    required this.fullName,
    required this.createdAt,
  });

  final int participationSequence;
  final String fullName;
  final DateTime createdAt;

  @override
  List<Object?> get props => [participationSequence, fullName, createdAt];
}

class GiveawayAnalyticsState extends Equatable {
  const GiveawayAnalyticsState({
    this.status = GiveawayAnalyticsStatus.loading,
    this.giveaway,
    this.recentParticipants = const [],
    this.dailyGrowth = const [],
    this.activeToday = 0,
    this.winners = const [],
    this.isSelectingWinner = false,
    this.failure,
  });

  final GiveawayAnalyticsStatus status;
  final Giveaway? giveaway;
  final List<RecentParticipant> recentParticipants;

  /// 7 buckets, oldest -> newest (today last).
  final List<int> dailyGrowth;
  final int activeToday;
  final List<Winner> winners;
  final bool isSelectingWinner;
  final Failure? failure;

  GiveawayAnalyticsState copyWith({
    GiveawayAnalyticsStatus? status,
    Giveaway? giveaway,
    List<RecentParticipant>? recentParticipants,
    List<int>? dailyGrowth,
    int? activeToday,
    List<Winner>? winners,
    bool? isSelectingWinner,
    Failure? failure,
  }) {
    return GiveawayAnalyticsState(
      status: status ?? this.status,
      giveaway: giveaway ?? this.giveaway,
      recentParticipants: recentParticipants ?? this.recentParticipants,
      dailyGrowth: dailyGrowth ?? this.dailyGrowth,
      activeToday: activeToday ?? this.activeToday,
      winners: winners ?? this.winners,
      isSelectingWinner: isSelectingWinner ?? this.isSelectingWinner,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    giveaway,
    recentParticipants,
    dailyGrowth,
    activeToday,
    winners,
    isSelectingWinner,
    failure,
  ];
}
