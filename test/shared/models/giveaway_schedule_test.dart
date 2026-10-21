import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/shared/models/giveaway.dart';

void main() {
  Giveaway giveaway({GiveawayStatus status = GiveawayStatus.scheduled}) => Giveaway(
    id: 'test',
    title: 'Test',
    organizerName: 'Organizer',
    prizeDescription: '',
    descriptionRules: '',
    imageUrl: null,
    startDate: DateTime(2026, 10, 20),
    endDate: DateTime(2026, 10, 30),
    endTime: '18:00',
    status: status,
    startsAtUtc: DateTime.utc(2026, 10, 20, 7),
    endsAtUtc: DateTime.utc(2026, 10, 30, 16),
    numberDigitWidth: 4,
    maxParticipants: null,
    participantCount: 0,
  );
  test('scheduled status changes at exact UTC boundaries without waiting for cron', () {
    final g = giveaway();
    expect(g.effectiveStatusAt(DateTime.utc(2026, 10, 20, 6, 59)), GiveawayStatus.scheduled);
    expect(g.effectiveStatusAt(DateTime.utc(2026, 10, 20, 7)), GiveawayStatus.active);
    expect(g.effectiveStatusAt(DateTime.utc(2026, 10, 30, 16)), GiveawayStatus.ended);
    expect(Giveaway.fromJson(g.toJson()).startsAtUtc, g.startsAtUtc);
  });
  test('manual ended and unpublished drafts remain closed', () {
    expect(
      giveaway(status: GiveawayStatus.ended).effectiveStatusAt(DateTime.utc(2026, 10, 22)),
      GiveawayStatus.ended,
    );
    expect(
      giveaway(status: GiveawayStatus.draft).effectiveStatusAt(DateTime.utc(2026, 10, 22)),
      GiveawayStatus.draft,
    );
  });
  test('legacy rows retain the database UTC interpretation and display in local time', () {
    final json = giveaway().toJson()
      ..remove('starts_at')
      ..remove('ends_at');
    final legacy = Giveaway.fromJson(json);
    expect(legacy.startsAt.toUtc(), DateTime.utc(2026, 10, 20));
    expect(legacy.endsAt.toUtc(), DateTime.utc(2026, 10, 30, 18));
  });
}
