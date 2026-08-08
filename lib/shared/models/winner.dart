import 'package:equatable/equatable.dart';

/// A selected winner, optionally joined with its giveaway/participation for
/// the celebration check and analytics winner list.
class Winner extends Equatable {
  const Winner({
    required this.id,
    required this.giveawayId,
    required this.participationId,
    required this.rank,
    required this.selectedAt,
    required this.celebrationAcknowledgedAt,
    this.giveawayTitle,
    this.giveawayImageUrl,
    this.participationNumber,
  });

  final String id;
  final String giveawayId;
  final String participationId;
  final int rank;
  final DateTime selectedAt;
  final DateTime? celebrationAcknowledgedAt;
  final String? giveawayTitle;
  final String? giveawayImageUrl;
  final int? participationNumber;

  bool get isCelebrationPending => celebrationAcknowledgedAt == null;

  factory Winner.fromJson(Map<String, dynamic> json) {
    final giveaway = json['giveaways'] as Map<String, dynamic>?;
    final participation = json['participations'] as Map<String, dynamic>?;
    return Winner(
      id: json['id'] as String,
      giveawayId: json['giveaway_id'] as String,
      participationId: json['participation_id'] as String,
      rank: json['rank'] as int? ?? 1,
      selectedAt: DateTime.parse(json['selected_at'] as String),
      celebrationAcknowledgedAt: (json['celebration_acknowledged_at'] as String?) != null
          ? DateTime.parse(json['celebration_acknowledged_at'] as String)
          : null,
      giveawayTitle: giveaway?['title'] as String?,
      giveawayImageUrl: giveaway?['image_url'] as String?,
      participationNumber: participation?['participation_number'] as int?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    giveawayId,
    participationId,
    rank,
    selectedAt,
    celebrationAcknowledgedAt,
  ];
}
