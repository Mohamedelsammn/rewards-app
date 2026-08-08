import 'package:equatable/equatable.dart';

enum RequirementType { follow, share, tagFriends, custom }

RequirementType _typeFromString(String? value) {
  switch (value) {
    case 'follow':
      return RequirementType.follow;
    case 'share':
      return RequirementType.share;
    case 'tag_friends':
      return RequirementType.tagFriends;
    default:
      return RequirementType.custom;
  }
}

/// Informational/soft requirement (implementation-plan.md §1.4 #8) -- no
/// server-side verification exists for these in the MVP; they're display-only
/// steps shown on Giveaway Details.
class GiveawayRequirement extends Equatable {
  const GiveawayRequirement({
    required this.id,
    required this.type,
    required this.label,
    required this.externalUrl,
    required this.sortOrder,
  });

  final String id;
  final RequirementType type;
  final String label;
  final String? externalUrl;
  final int sortOrder;

  factory GiveawayRequirement.fromJson(Map<String, dynamic> json) => GiveawayRequirement(
    id: json['id'] as String,
    type: _typeFromString(json['type'] as String?),
    label: json['label'] as String? ?? '',
    externalUrl: json['external_url'] as String?,
    sortOrder: json['sort_order'] as int? ?? 0,
  );

  @override
  List<Object?> get props => [id, type, label, externalUrl, sortOrder];
}
