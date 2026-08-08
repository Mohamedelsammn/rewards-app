import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/features/scratch_card/presentation/widgets/scratch_card_widget.dart';

void main() {
  testWidgets('dragging across the card reports increasing scratch progress', (tester) async {
    final progressUpdates = <double>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 200,
            child: ScratchCardWidget(
              onProgressChanged: progressUpdates.add,
              child: const ColoredBox(color: Colors.green, child: Text('4821')),
            ),
          ),
        ),
      ),
    );

    final finder = find.byType(ScratchCardWidget);
    final topLeft = tester.getTopLeft(finder);
    final size = tester.getSize(finder);

    final gesture = await tester.startGesture(topLeft + const Offset(5, 5));
    // Sweep across the whole card in a grid pattern so enough cells get marked.
    for (var y = 0; y < size.height; y += 12) {
      for (var x = 0; x < size.width; x += 12) {
        await gesture.moveTo(topLeft + Offset(x.toDouble(), y.toDouble()));
        await tester.pump(const Duration(milliseconds: 1));
      }
    }
    await gesture.up();
    await tester.pump();

    expect(progressUpdates, isNotEmpty);
    expect(progressUpdates.last, greaterThanOrEqualTo(0.6));
    // Progress should be non-decreasing across the whole gesture.
    for (var i = 1; i < progressUpdates.length; i++) {
      expect(progressUpdates[i], greaterThanOrEqualTo(progressUpdates[i - 1]));
    }
  });

  testWidgets('isRevealed=true removes the interactive foil layer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 200,
            child: ScratchCardWidget(
              isRevealed: true,
              onProgressChanged: (_) {},
              child: const ColoredBox(color: Colors.green, child: Text('4821')),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(GestureDetector), findsNothing);
    expect(find.text('4821'), findsOneWidget);
  });
}
