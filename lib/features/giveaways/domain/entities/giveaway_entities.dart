import 'package:equatable/equatable.dart';

import '../../../../core/localization/localized_text.dart';

enum GiveawayStatus { upcoming, active, ended, winnersSelected, completed, cancelled }

GiveawayStatus giveawayStatusFrom(String? value) => switch (value) {
  'UPCOMING' => GiveawayStatus.upcoming,
  'ACTIVE' => GiveawayStatus.active,
  'WINNERS_SELECTED' => GiveawayStatus.winnersSelected,
  'COMPLETED' => GiveawayStatus.completed,
  'CANCELLED' => GiveawayStatus.cancelled,
  _ => GiveawayStatus.ended,
};

/// Filter values of `GET /giveaways?status=`.
enum GiveawayListFilter {
  available('AVAILABLE'),
  upcoming('UPCOMING'),
  ended('ENDED');

  const GiveawayListFilter(this.apiValue);

  final String apiValue;
}

enum StepVerification { none, linkClick, adminReview }

class GiveawayStep extends Equatable {
  const GiveawayStep({
    required this.id,
    required this.title,
    required this.verification,
    this.kind = '',
    this.url,
    this.required = true,
    this.sortOrder = 0,
  });

  final String id;
  final String kind;
  final LocalizedText title;
  final String? url;
  final StepVerification verification;
  final bool required;
  final int sortOrder;

  @override
  List<Object?> get props => [id, kind, title, url, verification, required, sortOrder];
}

enum StepProgressStatus { completed, submitted, approved, rejected }

class StepProgress extends Equatable {
  const StepProgress({required this.stepId, required this.status, this.note});

  final String stepId;
  final StepProgressStatus status;
  final String? note;

  /// Counts as done for entry purposes (admin review still pending is fine).
  bool get isDone => status != StepProgressStatus.rejected;

  @override
  List<Object?> get props => [stepId, status, note];
}

class Giveaway extends Equatable {
  const Giveaway({
    required this.id,
    required this.title,
    required this.status,
    this.description = const LocalizedText(),
    this.prize = const LocalizedText(),
    this.rules = const LocalizedText(),
    this.organizer = '',
    this.imageUrl,
    this.startsAt,
    this.endsAt,
    this.participants = 0,
    this.maxParticipants,
    this.winnersCount = 1,
    this.numberDigits = 6,
    this.steps = const [],
  });

  final String id;
  final LocalizedText title;
  final LocalizedText description;
  final LocalizedText prize;
  final LocalizedText rules;
  final String organizer;
  final String? imageUrl;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final GiveawayStatus status;
  final int participants;
  final int? maxParticipants;
  final int winnersCount;
  final int numberDigits;
  final List<GiveawayStep> steps;

  bool get isUpcoming => status == GiveawayStatus.upcoming;
  bool get isActive => status == GiveawayStatus.active;

  /// Every place is taken (`maxParticipants` is `null` when unlimited).
  bool get isFull => maxParticipants != null && participants >= maxParticipants!;
  bool get hasResults =>
      status == GiveawayStatus.winnersSelected || status == GiveawayStatus.completed;

  @override
  List<Object?> get props => [id, title, status, participants, steps, imageUrl, endsAt];
}

enum EntryResult { pending, won, notSelected }

class GiveawayEntry extends Equatable {
  const GiveawayEntry({
    required this.id,
    required this.giveawayId,
    required this.participationNumber,
    required this.active,
    this.createdAt,
    this.result,
    this.winnerId,
    this.giveawayTitle = const LocalizedText(),
    this.giveawayImageUrl,
    this.giveawayEndsAt,
  });

  final String id;
  final String giveawayId;

  /// Zero-padded string from the server; displayed as-is, always LTR.
  final String participationNumber;

  /// `false` when the entry was disqualified.
  final bool active;
  final DateTime? createdAt;
  final EntryResult? result;
  final String? winnerId;
  final LocalizedText giveawayTitle;
  final String? giveawayImageUrl;
  final DateTime? giveawayEndsAt;

  @override
  List<Object?> get props => [id, giveawayId, participationNumber, active, result, winnerId];
}

/// `GET /giveaways/:id` with the caller's own entry and step progress.
class GiveawayDetails extends Equatable {
  const GiveawayDetails({required this.giveaway, this.entry, this.progress = const {}});

  final Giveaway giveaway;
  final GiveawayEntry? entry;
  final Map<String, StepProgress> progress;

  List<GiveawayStep> get remainingRequiredSteps => [
    for (final step in giveaway.steps)
      if (step.required && !(progress[step.id]?.isDone ?? false)) step,
  ];

  @override
  List<Object?> get props => [giveaway, entry, progress];
}

class GiveawayWinner extends Equatable {
  const GiveawayWinner({required this.rank, required this.participationNumber, this.announcedAt});

  final int rank;
  final String participationNumber;
  final DateTime? announcedAt;

  @override
  List<Object?> get props => [rank, participationNumber, announcedAt];
}

enum WinningStatus { announced, claimed, fulfilled, forfeited }

class Winning extends Equatable {
  const Winning({
    required this.id,
    required this.giveawayId,
    required this.status,
    required this.participationNumber,
    this.rank = 1,
    this.claimDeadline,
    this.claimedAt,
    this.title = const LocalizedText(),
    this.prize = const LocalizedText(),
    this.imageUrl,
  });

  final String id;
  final String giveawayId;
  final int rank;
  final WinningStatus status;
  final DateTime? claimDeadline;
  final DateTime? claimedAt;
  final LocalizedText title;
  final LocalizedText prize;
  final String? imageUrl;
  final String participationNumber;

  bool get canClaim =>
      status == WinningStatus.announced &&
      (claimDeadline == null || claimDeadline!.isAfter(DateTime.now()));

  @override
  List<Object?> get props => [id, giveawayId, status, claimedAt, participationNumber];
}
