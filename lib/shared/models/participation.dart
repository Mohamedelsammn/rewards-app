import 'package:equatable/equatable.dart';

/// A user's participation in a giveaway. `participationNumber` (bounded,
/// 4-6 digit "lucky number") and `participationSequence` (unbounded admin
/// ticket #) are intentionally decoupled -- see implementation-plan.md
/// §1.4 #1 and §16.
class Participation extends Equatable {
  const Participation({
    required this.id,
    required this.giveawayId,
    required this.participationSequence,
    required this.participationNumber,
    required this.scratchRevealedAt,
    required this.createdAt,
    this.giveaway,
    this.isWinner = false,
    this.rewardedFrameUnlocked = false,
  });

  final String id;
  final String giveawayId;
  final int participationSequence;
  final int participationNumber;
  final DateTime? scratchRevealedAt;
  final DateTime createdAt;

  /// Populated when fetched joined with its giveaway (My Giveaways list).
  final Map<String, dynamic>? giveaway;

  /// True when a `winners` row exists for this participation -- populated
  /// only when fetched joined with `winners(id)` (My Giveaways list). Lets
  /// a finished giveaway distinguish "you won" from "not selected" without
  /// a second round trip.
  final bool isWinner;
  final bool rewardedFrameUnlocked;

  String get formattedNumber => participationNumber.toString().padLeft(4, '0');

  Participation copyWith({
    Map<String, dynamic>? giveaway,
    bool? isWinner,
    bool? rewardedFrameUnlocked,
  }) => Participation(
    id: id,
    giveawayId: giveawayId,
    participationSequence: participationSequence,
    participationNumber: participationNumber,
    scratchRevealedAt: scratchRevealedAt,
    createdAt: createdAt,
    giveaway: giveaway ?? this.giveaway,
    isWinner: isWinner ?? this.isWinner,
    rewardedFrameUnlocked: rewardedFrameUnlocked ?? this.rewardedFrameUnlocked,
  );

  factory Participation.fromJson(Map<String, dynamic> json) => Participation(
    id: json['id'] as String? ?? json['participationId'] as String,
    giveawayId: json['giveaway_id'] as String? ?? json['giveawayId'] as String? ?? '',
    participationSequence:
        json['participation_sequence'] as int? ?? json['participationSequence'] as int? ?? 0,
    participationNumber:
        json['participation_number'] as int? ?? json['participationNumber'] as int? ?? 0,
    scratchRevealedAt: (json['scratch_revealed_at'] as String?) != null
        ? DateTime.parse(json['scratch_revealed_at'] as String)
        : null,
    createdAt: DateTime.parse((json['created_at'] ?? json['createdAt']) as String),
    giveaway: json['giveaways'] as Map<String, dynamic>?,
    isWinner: (json['winners'] as List?)?.isNotEmpty ?? false,
    // The repository hydrates this from device-local storage after parsing.
    // Never accept a server/client JSON field (including legacy SSV columns)
    // as proof of a local cosmetic entitlement.
    rewardedFrameUnlocked: false,
  );

  @override
  List<Object?> get props => [
    id,
    giveawayId,
    participationSequence,
    participationNumber,
    scratchRevealedAt,
    createdAt,
    isWinner,
    rewardedFrameUnlocked,
    giveaway,
  ];
}
