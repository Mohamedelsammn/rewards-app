import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';

enum AdminAnalysisStatus { loading, loaded, empty, error }

class AdminAnalysisState extends Equatable {
  const AdminAnalysisState({
    this.status = AdminAnalysisStatus.loading,
    this.totalGiveaways = 0,
    this.activeCount = 0,
    this.finishedCount = 0,
    this.totalParticipants = 0,
    this.totalWinners = 0,

    /// 7 buckets, oldest -> newest (today last), summed across every
    /// giveaway this admin owns.
    this.dailyGrowth = const [],
    this.failure,
  });

  final AdminAnalysisStatus status;
  final int totalGiveaways;
  final int activeCount;
  final int finishedCount;
  final int totalParticipants;
  final int totalWinners;
  final List<int> dailyGrowth;
  final Failure? failure;

  AdminAnalysisState copyWith({
    AdminAnalysisStatus? status,
    int? totalGiveaways,
    int? activeCount,
    int? finishedCount,
    int? totalParticipants,
    int? totalWinners,
    List<int>? dailyGrowth,
    Failure? failure,
  }) {
    return AdminAnalysisState(
      status: status ?? this.status,
      totalGiveaways: totalGiveaways ?? this.totalGiveaways,
      activeCount: activeCount ?? this.activeCount,
      finishedCount: finishedCount ?? this.finishedCount,
      totalParticipants: totalParticipants ?? this.totalParticipants,
      totalWinners: totalWinners ?? this.totalWinners,
      dailyGrowth: dailyGrowth ?? this.dailyGrowth,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    totalGiveaways,
    activeCount,
    finishedCount,
    totalParticipants,
    totalWinners,
    dailyGrowth,
    failure,
  ];
}
