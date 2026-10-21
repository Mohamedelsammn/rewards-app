import 'package:flutter/material.dart';
import 'package:rewardsapp/core/theme/app_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/shared/widgets/hero_back_button.dart';

void main() {
  testWidgets('has a hit target of at least 44x44 logical pixels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Stack(children: [HeroBackButton()])),
      ),
    );

    final size = tester.getSize(find.byType(InkWell));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('pops the current route by default when tapped', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const Scaffold(
                      body: Stack(
                        children: [
                          Center(child: Text('second page')),
                          HeroBackButton(),
                        ],
                      ),
                    ),
                  ),
                ),
                child: const Text('first page'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('first page'));
    await tester.pumpAndSettle();
    expect(find.text('second page'), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();

    expect(find.text('second page'), findsNothing);
    expect(find.text('first page'), findsOneWidget);
  });

  testWidgets('invokes a custom onTap instead of popping when provided', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(children: [HeroBackButton(onTap: () => tapped = true)]),
        ),
      ),
    );

    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
