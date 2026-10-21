import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../shared/models/eligible_participant.dart';
import '../../../../shared/models/giveaway.dart';
import '../../../../shared/models/winner.dart';

enum GiveawayAnalyticsStatus { loading, loaded, error }

class RecentParticipant extends Equatable {
  const RecentParticipant({
    required this.participationSequence,
    required this.participationNumber,
    required this.fullName,
    required this.createdAt,
    this.phoneE164,
  });

  final int participationSequence;

  /// The visible participation code (random, server-allocated 4-digit
  /// number) -- the PRIMARY identifier shown to the admin. Kept alongside
  /// [participationSequence] (an internal, never-displayed ticket ordinal)
  /// for anything that still needs stable chronological ordering.
  final int participationNumber;
  final String fullName;
  final DateTime createdAt;
  final String? phoneE164;

  String get formattedParticipationNumber => participationNumber.toString().padLeft(4, '0');

  @override
  List<Object?> get props => [
    participationSequence,
    participationNumber,
    fullName,
    createdAt,
    phoneE164,
  ];
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
    this.manualTarget,
    this.lastSelectedWinner,
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

  /// The admin's pending manual pick from the participant picker sheet --
  /// UI/state only, it does NOT make this participant a winner. Only
  /// [GiveawayAnalyticsCubit.selectWinner] consuming it (when the admin
  /// presses "Select Winner"/"Select Another Winner") actually finalizes
  /// anything, and it's cleared the moment that happens (win or lose) since
  /// a stale pending pick must never silently carry over to the next
  /// selection. Unlike [failure], this is preserved across unrelated state
  /// updates (e.g. a realtime-triggered [GiveawayAnalyticsCubit.load]) --
  /// see [copyWith]'s `clearManualTarget` flag for how it's explicitly reset.
  final EligibleParticipant? manualTarget;

  /// The full [Winner] record from the most recently confirmed selection --
  /// distinct from [winners] (which only refreshes once [load] completes,
  /// asynchronously). The winner wheel reveal needs this available the
  /// instant the server confirms a pick, without waiting on that reload.
  final Winner? lastSelectedWinner;

  GiveawayAnalyticsState copyWith({
    GiveawayAnalyticsStatus? status,
    Giveaway? giveaway,
    List<RecentParticipant>? recentParticipants,
    List<int>? dailyGrowth,
    int? activeToday,
    List<Winner>? winners,
    bool? isSelectingWinner,
    Failure? failure,
    EligibleParticipant? manualTarget,
    bool clearManualTarget = false,
    Winner? lastSelectedWinner,
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
      manualTarget: clearManualTarget ? null : (manualTarget ?? this.manualTarget),
      lastSelectedWinner: lastSelectedWinner ?? this.lastSelectedWinner,
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
    manualTarget,
    lastSelectedWinner,
  ];
}
