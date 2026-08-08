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

  /// Combines end_date + end_time into a single instant for countdowns.
  DateTime get endsAt {
    final parts = endTime.split(':');
    final hour = int.tryParse(parts.elementAtOrNull(0) ?? '') ?? 0;
    final minute = int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0;
    return DateTime(endDate.year, endDate.month, endDate.day, hour, minute);
  }

  Duration get timeRemaining {
    final remaining = endsAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isJoinable => status == GiveawayStatus.active && timeRemaining > Duration.zero;

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
  ];
}

extension _ElementAtOrNull<T> on List<T> {
  T? elementAtOrNull(int index) => index < length ? this[index] : null;
}
