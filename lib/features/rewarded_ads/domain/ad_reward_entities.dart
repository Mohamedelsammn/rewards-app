import 'package:equatable/equatable.dart';

class AdRewardStatus extends Equatable {
  const AdRewardStatus({
    required this.enabled,
    this.verification = '',
    this.pointsPerCompletedAd = 0,
    this.dailyLimit = 0,
    this.usedToday = 0,
    this.remainingToday = 0,
    this.cooldownSeconds = 0,
    this.nextAvailableAt,
  });

  /// The verification mode this app implements (FLUTTER_ADS-1.md).
  static const clientReported = 'CLIENT_REPORTED';

  final bool enabled;

  /// Server verification mode; only [clientReported] is supported.
  final String verification;
  final int pointsPerCompletedAd;
  final int dailyLimit;
  final int usedToday;
  final int remainingToday;
  final int cooldownSeconds;
  final DateTime? nextAvailableAt;

  bool get isClientReported => verification == clientReported;

  bool get inCooldown => nextAvailableAt != null && nextAvailableAt!.isAfter(DateTime.now());

  @override
  List<Object?> get props => [
    enabled,
    verification,
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
    this.creditedAt,
  });

  final String id;
  final AdSessionStatus status;
  final int points;
  final String? rejectReason;
  final DateTime? expiresAt;

  /// Set once credited. (`verifiedAt` stays `null` in client-reported mode
  /// and is not used.)
  final DateTime? creditedAt;

  bool get isFinal => status != AdSessionStatus.pending;

  @override
  List<Object?> get props => [id, status, points, rejectReason];
}

/// Answer of `POST /ad-rewards/claims`.
class AdClaim extends Equatable {
  const AdClaim({required this.session, this.balance});

  final AdSession session;

  /// Wallet balance right after the claim (server value).
  final int? balance;

  @override
  List<Object?> get props => [session, balance];
}

/// Earn Points ads (FLUTTER_ADS-1.md, client-reported completion): status →
/// one-time session → rewarded ad → claim on `onUserEarnedReward`. The server
/// decides points, limits and cooldowns and credits the wallet.
abstract interface class AdRewardsRepository {
  Future<AdRewardStatus> status(String deviceId);

  /// `POST /ad-rewards/sessions`, before the ad is shown.
  Future<AdSession> createSession({required String deviceId, required String adUnitId});

  /// `GET /ad-rewards/sessions/:id`, diagnostics only.
  Future<AdSession> session(String id);

  /// `POST /ad-rewards/claims { sessionId }`, after the reward callback.
  /// Idempotent: retrying a credited session returns the same result.
  Future<AdClaim> claim(String sessionId);
}
