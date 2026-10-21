import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/features/giveaway_analytics/presentation/widgets/wheel_segments.dart';

void main() {
  group('buildWheelSegments', () {
    test('always includes the winner label exactly once', () {
      final result = buildWheelSegments(
        winnerLabel: '4821',
        decoyLabels: ['1111', '2222', '3333'],
        shuffle: (_) {}, // deterministic: preserve insertion order
      );

      expect(result.labels.where((l) => l == '4821').length, 1);
      expect(result.labels, containsAll(['1111', '2222', '3333', '4821']));
    });

    test('winningIndex always points at the winner label', () {
      final result = buildWheelSegments(
        winnerLabel: '4821',
        decoyLabels: ['1111', '2222', '3333'],
        shuffle: (_) {},
      );

      expect(result.labels[result.winningIndex], '4821');
    });

    test('never duplicates the winner even if it also appears in the decoy pool -- e.g. a '
        'manual target that happens to already be a Recent Participant', () {
      final result = buildWheelSegments(
        winnerLabel: '1111',
        decoyLabels: ['1111', '2222', '3333'],
        shuffle: (_) {},
      );

      expect(result.labels.where((l) => l == '1111').length, 1);
      expect(result.labels.length, 3); // 1111 (winner) + 2222 + 3333, no duplicate
    });

    test('caps decoys at maxDecoys -- the wheel never needs the entire eligible list', () {
      final decoys = List.generate(50, (i) => 'code$i');
      final result = buildWheelSegments(
        winnerLabel: 'winner',
        decoyLabels: decoys,
        maxDecoys: 9,
        shuffle: (_) {},
      );

      // 9 decoys + 1 winner.
      expect(result.labels.length, 10);
    });

    test('works with zero decoys -- the winner is the only wedge', () {
      final result = buildWheelSegments(
        winnerLabel: 'winner',
        decoyLabels: const [],
        shuffle: (_) {},
      );

      expect(result.labels, ['winner']);
      expect(result.winningIndex, 0);
    });

    test('deduplicates repeated decoy labels before capping', () {
      final result = buildWheelSegments(
        winnerLabel: 'winner',
        decoyLabels: ['1111', '1111', '1111', '2222'],
        shuffle: (_) {},
      );

      expect(result.labels.where((l) => l == '1111').length, 1);
    });
  });
}
