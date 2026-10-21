import 'package:equatable/equatable.dart';

class AdRewardStatus extends Equatable {
  const AdRewardStatus({
    required this.enabled,
    this.pointsPerCompletedAd = 0,
    this.dailyLimit = 0,
    this.usedToday = 0,
    this.remainingToday = 0,
    this.cooldownSeconds = 0,
    this.nextAvailableAt,
  });

  final bool enabled;
  final int pointsPerCompletedAd;
  final int dailyLimit;
  final int usedToday;
  final int remainingToday;
  final int cooldownSeconds;
  final DateTime? nextAvailableAt;

  bool get inCooldown => nextAvailableAt != null && nextAvailableAt!.isAfter(DateTime.now());

  @override
  List<Object?> get props => [
    enabled,
    pointsPerCompletedAd,
    usedToday,
    remainingToday,
    nextAvailableAt,
  ];
}

enum AdSessionStatus { pending, credited, rejected, expired }

class AdSession extends Equatable {
  const AdSession({
    required this.id,
    required this.status,
    this.points = 0,
    this.rejectReason,
    this.expiresAt,
  });

  final String id;
  final AdSessionStatus status;
  final int points;
  final String? rejectReason;
  final DateTime? expiresAt;

  bool get isFinal => status != AdSessionStatus.pending;

  @override
  List<Object?> get props => [id, status, points, rejectReason];
}

/// Values passed to AdMob `ServerSideVerificationOptions` before `show()`.
class SsvOptions extends Equatable {
  const SsvOptions({required this.userId, required this.customData});

  final String userId;
  final String customData;

  @override
  List<Object?> get props => [userId, customData];
}

abstract interface class AdRewardsRepository {
  Future<AdRewardStatus> status(String deviceId);

  Future<({AdSession session, SsvOptions ssv})> createSession({
    required String deviceId,
    required String adUnitId,
  });

  /// Polls a session. Points are credited only by Google's signed callback
  /// to the server; the app never claims a view itself.
  Future<AdSession> session(String id);
}
