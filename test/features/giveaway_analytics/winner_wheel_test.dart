import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/features/giveaway_analytics/presentation/widgets/winner_wheel.dart';

void main() {
  Future<void> pumpWheel(
    WidgetTester tester, {
    required List<String> segments,
    required int winningIndex,
    required VoidCallback onSpinComplete,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: WinnerWheel(
              segments: segments,
              winningIndex: winningIndex,
              onSpinComplete: onSpinComplete,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('calls onSpinComplete exactly once after the spin animation finishes', (
    tester,
  ) async {
    var completedCount = 0;
    await pumpWheel(
      tester,
      segments: const ['1111', '2222', '3333', '4444'],
      winningIndex: 2,
      onSpinComplete: () => completedCount++,
    );

    expect(completedCount, 0); // Not complete immediately.
    await tester.pumpAndSettle();

    expect(completedCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders correctly with only a single segment (no decoys available)', (tester) async {
    var completed = false;
    await pumpWheel(
      tester,
      segments: const ['1111'],
      winningIndex: 0,
      onSpinComplete: () => completed = true,
    );

    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not throw with a large segment list', (tester) async {
    final segments = List.generate(10, (i) => '${1000 + i}');
    var completed = false;
    await pumpWheel(
      tester,
      segments: segments,
      winningIndex: 7,
      onSpinComplete: () => completed = true,
    );

    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
