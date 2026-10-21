import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/redesign/demo_repository.dart';
import 'package:rewardsapp/redesign/redesign_app.dart';

class _OnboardingRepository extends ChangeNotifier implements RewardsRepository {
  int saves = 0;

  @override
  Future<bool> accountExists(String email) async => false;

  @override
  Future<void> saveOnboarding(String email, int stage) async => saves++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('reference progress has three bars and two dots', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AuthTop(step: 0))));
    final progress = find.byType(OnboardingProgress);
    expect(progress, findsOneWidget);
    final sizes = tester
        .widgetList<SizedBox>(find.descendant(of: progress, matching: find.byType(SizedBox)))
        .where((box) => box.width == 31 || box.width == 8)
        .map((box) => box.width)
        .toList();
    expect(sizes, [31, 8, 31, 8, 31]);
  });

  testWidgets('Email advances once and back keeps the entered address', (tester) async {
    final repository = _OnboardingRepository();
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      DemoScope(
        repository: repository,
        child: const MaterialApp(home: EmailPage()),
      ),
    );
    await tester.enterText(find.byType(TextField), 'user@example.com');
    await tester.ensureVisible(find.text('Send Code'));
    await tester.tap(find.text('Send Code'));
    await tester.pumpAndSettle();
    expect(find.byType(OtpPage), findsOneWidget);
    expect(tester.widget<OnboardingProgress>(find.byType(OnboardingProgress)).step, 1);
    expect(repository.saves, 1);
    await tester.tap(find.byIcon(Icons.arrow_back).last);
    await tester.pumpAndSettle();
    expect(find.byType(EmailPage), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'user@example.com');
    expect(tester.widget<OnboardingProgress>(find.byType(OnboardingProgress)).step, 0);
    expect(tester.takeException(), isNull);
  });
}
