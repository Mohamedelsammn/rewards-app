import '../../../core/localization/localized_text.dart';
import '../../../core/utils/cursor_page.dart';
import '../domain/entities/giveaway_entities.dart';

class GiveawayModels {
  const GiveawayModels._();

  static Giveaway giveaway(Map<String, dynamic> json) => Giveaway(
    id: '${json['id']}',
    title: LocalizedText.fromJson(json['title']),
    description: LocalizedText.fromJson(json['description']),
    prize: LocalizedText.fromJson(json['prize']),
    rules: LocalizedText.fromJson(json['rules']),
    organizer: json['organizer'] as String? ?? '',
    imageUrl: json['imageUrl'] as String?,
    startsAt: parseDate(json['startsAt']),
    endsAt: parseDate(json['endsAt']),
    status: giveawayStatusFrom(json['status'] as String?),
    participants: parseInt(json['participants']),
    maxParticipants: json['maxParticipants'] == null ? null : parseInt(json['maxParticipants']),
    winnersCount: parseInt(json['winnersCount'], 1),
    numberDigits: parseInt(json['numberDigits'], 6),
    steps: parseList(json['steps'], step)..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
  );

  static GiveawayStep step(Map<String, dynamic> json) => GiveawayStep(
    id: '${json['id']}',
    kind: json['kind'] as String? ?? '',
    title: LocalizedText.fromJson(json['title']),
    url: json['url'] as String?,
    verification: switch (json['verification']) {
      'ADMIN_REVIEW' => StepVerification.adminReview,
      'LINK_CLICK' => StepVerification.linkClick,
      _ => StepVerification.none,
    },
    required: json['required'] != false,
    sortOrder: parseInt(json['sortOrder']),
  );

  static StepProgress progress(String stepId, Map<String, dynamic> json) => StepProgress(
    stepId: stepId,
    status: switch (json['status']) {
      'SUBMITTED' => StepProgressStatus.submitted,
      'APPROVED' => StepProgressStatus.approved,
      'REJECTED' => StepProgressStatus.rejected,
      _ => StepProgressStatus.completed,
    },
    note: json['note'] as String?,
  );

  static GiveawayEntry entry(Map<String, dynamic> json) {
    final giveaway = json['giveaway'] is Map ? json['giveaway'] as Map : const {};
    return GiveawayEntry(
      id: '${json['id']}',
      giveawayId: '${json['giveawayId']}',
      participationNumber: '${json['participationNumber'] ?? ''}',
      active: json['status'] != 'DISQUALIFIED',
      createdAt: parseDate(json['createdAt']),
      result: switch (json['result']) {
        'WON' => EntryResult.won,
        'NOT_SELECTED' => EntryResult.notSelected,
        'PENDING' => EntryResult.pending,
        _ => null,
      },
      winnerId: json['winnerId'] as String?,
      giveawayTitle: LocalizedText.fromJson(giveaway['title']),
      giveawayImageUrl: giveaway['imageUrl'] as String?,
      giveawayEndsAt: parseDate(giveaway['endsAt']),
    );
  }

  static GiveawayDetails details(Map<String, dynamic> json) {
    final me = json['me'] is Map ? Map<String, dynamic>.from(json['me'] as Map) : null;
    final steps = me?['steps'] is Map ? me!['steps'] as Map : const {};
    return GiveawayDetails(
      giveaway: giveaway(Map<String, dynamic>.from(json['giveaway'] as Map)),
      entry: me?['entry'] is Map ? entry(Map<String, dynamic>.from(me!['entry'] as Map)) : null,
      progress: {
        for (final item in steps.entries)
          if (item.value is Map)
            '${item.key}': progress('${item.key}', Map<String, dynamic>.from(item.value as Map)),
      },
    );
  }

  static GiveawayWinner winner(Map<String, dynamic> json) => GiveawayWinner(
    rank: parseInt(json['rank'], 1),
    participationNumber: '${json['participationNumber'] ?? ''}',
    announcedAt: parseDate(json['announcedAt']),
  );

  static Winning winning(Map<String, dynamic> json) {
    final giveaway = json['giveaway'] is Map ? json['giveaway'] as Map : const {};
    return Winning(
      id: '${json['id']}',
      giveawayId: '${json['giveawayId']}',
      rank: parseInt(json['rank'], 1),
      status: switch (json['status']) {
        'CLAIMED' => WinningStatus.claimed,
        'FULFILLED' => WinningStatus.fulfilled,
        'FORFEITED' => WinningStatus.forfeited,
        _ => WinningStatus.announced,
      },
      claimDeadline: parseDate(json['claimDeadline']),
      claimedAt: parseDate(json['claimedAt']),
      title: LocalizedText.fromJson(giveaway['title']),
      prize: LocalizedText.fromJson(giveaway['prize']),
      imageUrl: giveaway['imageUrl'] as String?,
      participationNumber: '${json['participationNumber'] ?? ''}',
    );
  }
}
