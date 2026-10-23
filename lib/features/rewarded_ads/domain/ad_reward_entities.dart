import 'package:equatable/equatable.dart';

class AdRewardStatus extends Equatable {
  const AdRewardStatus({
    required this.enabled,
    this.verification = '',
    this.ticketsPerCompletedAd = 0,
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
  final int ticketsPerCompletedAd;
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
    ticketsPerCompletedAd,
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
    this.tickets = 0,
    this.rejectReason,
    this.expiresAt,
    this.creditedAt,
  });

  final String id;
  final AdSessionStatus status;

  /// Tickets this session credits. Tickets are not redeemable (AdMob policy).
  final int tickets;
  final String? rejectReason;
  final DateTime? expiresAt;

  /// Set once credited. (`verifiedAt` stays `null` in client-reported mode
  /// and is not used.)
  final DateTime? creditedAt;

  bool get isFinal => status != AdSessionStatus.pending;

  @override
  List<Object?> get props => [id, status, tickets, rejectReason];
}

/// Answer of `POST /ad-rewards/claims`.
class AdClaim extends Equatable {
  const AdClaim({required this.session, this.tickets});

  final AdSession session;

  /// Tickets balance right after the claim (server value).
  final int? tickets;

  @override
  List<Object?> get props => [session, tickets];
}

/// Earn Tickets ads (FLUTTER_ADS-1.md, client-reported completion): status →
/// one-time session → rewarded ad → claim on `onUserEarnedReward`. The server
/// decides tickets, limits and cooldowns and credits the tickets balance.
/// Ads never credit redeemable points.
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
