import 'package:equatable/equatable.dart';

enum GiveawayStatus { draft, scheduled, active, ended, archived, unknown }

GiveawayStatus giveawayStatusFromString(String? value) {
  switch (value) {
    case 'draft':
      return GiveawayStatus.draft;
    case 'scheduled':
      return GiveawayStatus.scheduled;
    case 'active':
      return GiveawayStatus.active;
    case 'ended':
      return GiveawayStatus.ended;
    case 'archived':
      return GiveawayStatus.archived;
    default:
      return GiveawayStatus.unknown;
  }
}

class Giveaway extends Equatable {
  const Giveaway({
    required this.id,
    required this.title,
    required this.organizerName,
    required this.prizeDescription,
    required this.descriptionRules,
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.endTime,
    required this.status,
    required this.numberDigitWidth,
    required this.maxParticipants,
    required this.participantCount,
    this.categoryId,
    this.startsAtUtc,
    this.endsAtUtc,
  });

  final String id;
  final String title;
  final String organizerName;
  final String prizeDescription;
  final String descriptionRules;
  final String? imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final String endTime;
  final GiveawayStatus status;
  final int numberDigitWidth;
  final int? maxParticipants;
  final int participantCount;
  final String? categoryId;
  final DateTime? startsAtUtc;
  final DateTime? endsAtUtc;
  DateTime get startsAt =>
      (startsAtUtc ?? DateTime.utc(startDate.year, startDate.month, startDate.day)).toLocal();
  GiveawayStatus effectiveStatusAt(DateTime now) {
    if (status == GiveawayStatus.draft ||
        status == GiveawayStatus.archived ||
        status == GiveawayStatus.unknown) {
      return status;
    }
    if (!now.isBefore(endsAt)) return GiveawayStatus.ended;
    if (status == GiveawayStatus.ended) return status;
    return now.isBefore(startsAt) ? GiveawayStatus.scheduled : GiveawayStatus.active;
  }

  GiveawayStatus get effectiveStatus => effectiveStatusAt(DateTime.now());

  /// Combines end_date + end_time into a single instant for countdowns.
  DateTime get endsAt {
    if (endsAtUtc != null) return endsAtUtc!.toLocal();
    final parts = endTime.split(':');
    final hour = int.tryParse(parts.elementAtOrNull(0) ?? '') ?? 0;
    final minute = int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0;
    return DateTime.utc(endDate.year, endDate.month, endDate.day, hour, minute).toLocal();
  }

  Duration get timeRemaining {
    final remaining = endsAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isJoinable => effectiveStatus == GiveawayStatus.active;

  factory Giveaway.fromJson(Map<String, dynamic> json) {
    return Giveaway(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      organizerName: json['organizer_name'] as String? ?? '',
      prizeDescription: json['prize_description'] as String? ?? '',
      descriptionRules: json['description_rules'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      endTime: (json['end_time'] as String? ?? '00:00:00').substring(0, 5),
      status: giveawayStatusFromString(json['status'] as String?),
      numberDigitWidth: json['number_digit_width'] as int? ?? 4,
      maxParticipants: json['max_participants'] as int?,
      participantCount: json['participant_count'] as int? ?? 0,
      categoryId: json['category_id'] as String?,
      startsAtUtc: DateTime.tryParse(json['starts_at'] as String? ?? '')?.toUtc(),
      endsAtUtc: DateTime.tryParse(json['ends_at'] as String? ?? '')?.toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'organizer_name': organizerName,
    'prize_description': prizeDescription,
    'description_rules': descriptionRules,
    'image_url': imageUrl,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'end_time': endTime,
    'status': status.name,
    'number_digit_width': numberDigitWidth,
    'max_participants': maxParticipants,
    'participant_count': participantCount,
    'category_id': categoryId,
    'starts_at': startsAtUtc?.toIso8601String(),
    'ends_at': endsAtUtc?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    title,
    organizerName,
    prizeDescription,
    descriptionRules,
    imageUrl,
    startDate,
    endDate,
    endTime,
    status,
    numberDigitWidth,
    maxParticipants,
    participantCount,
    categoryId,
    startsAtUtc,
    endsAtUtc,
  ];
}

extension _ElementAtOrNull<T> on List<T> {
  T? elementAtOrNull(int index) => index < length ? this[index] : null;
}
