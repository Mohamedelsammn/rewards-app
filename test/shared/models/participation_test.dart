import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/shared/models/participation.dart';

/// Covers Participation.fromJson's `winners` embed -> isWinner mapping,
/// added so User My Giveaways can tell "you won" apart from "not selected"
/// for a finished giveaway without a second round trip (see
/// ParticipationRepository.getMyParticipations' `winners(id)` embed).
void main() {
  group('Participation.fromJson', () {
    test('isWinner is true when the winners embed is a non-empty list', () {
      final participation = Participation.fromJson({
        'id': 'p1',
        'giveaway_id': 'g1',
        'participation_sequence': 1,
        'participation_number': 42,
        'created_at': '2026-01-01T00:00:00Z',
        'winners': [
          {'id': 'w1'},
        ],
      });

      expect(participation.isWinner, isTrue);
    });

    test('isWinner is false when the winners embed is an empty list', () {
      final participation = Participation.fromJson({
        'id': 'p1',
        'giveaway_id': 'g1',
        'participation_sequence': 1,
        'participation_number': 42,
        'created_at': '2026-01-01T00:00:00Z',
        'winners': <Map<String, dynamic>>[],
      });

      expect(participation.isWinner, isFalse);
    });

    test('isWinner defaults to false when the winners key is absent '
        '(e.g. create-participation\'s response, which never embeds it)', () {
      final participation = Participation.fromJson({
        'participationId': 'p1',
        'giveawayId': 'g1',
        'participationSequence': 1,
        'participationNumber': 42,
        'createdAt': '2026-01-01T00:00:00Z',
      });

      expect(participation.isWinner, isFalse);
    });
  });
}
