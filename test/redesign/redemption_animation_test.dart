import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/redesign/demo_repository.dart';
import 'package:rewardsapp/redesign/redemption_details_sheet.dart';
import 'package:rewardsapp/redesign/redesign_app.dart';

class _Box extends Mock implements Box<dynamic> {}

class _Secure extends Mock implements FlutterSecureStorage {}

Finder imageAsset(String path) => find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName == path,
);

void main() {
  late LocalRewardsRepository repo;

  setUp(() {
    final box = _Box();
    final secure = _Secure();
    final data = <dynamic, dynamic>{};
    final secrets = <String, String>{};
    when(() => box.get(any(), defaultValue: any(named: 'defaultValue'))).thenAnswer(
      (call) => data[call.positionalArguments.first] ?? call.namedArguments[#defaultValue],
    );
    when(() => box.put(any(), any())).thenAnswer((call) async {
      data[call.positionalArguments[0]] = call.positionalArguments[1];
    });
    when(() => box.putAll(any())).thenAnswer((call) async {
      data.addAll(call.positionalArguments.first as Map<dynamic, dynamic>);
    });
    when(() => box.delete(any())).thenAnswer((call) async {
      data.remove(call.positionalArguments.first);
    });
    when(
      () => secure.read(key: any(named: 'key')),
    ).thenAnswer((call) async => secrets[call.namedArguments[#key]]);
    when(
      () => secure.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((call) async {
      secrets[call.namedArguments[#key]] = call.namedArguments[#value] as String;
    });
    when(() => secure.delete(key: any(named: 'key'))).thenAnswer((call) async {
      secrets.remove(call.namedArguments[#key]);
    });
    repo = LocalRewardsRepository(box, secure);
  });

  test('demo fulfillment definitions select the required product-specific fields', () {
    expect(demoProducts.first.fulfillmentFields.single.key, 'player_id');
    expect(demoProducts.first.fulfillmentFields.single.confirmEntry, isTrue);
    expect(
      demoProducts.firstWhere((p) => p.categoryId == 'tactical').fulfillmentFields.single.key,
      'riot_id',
    );
    expect(
      demoProducts.firstWhere((p) => p.categoryId == 'social').fulfillmentFields.single.key,
      'profile',
    );
    expect(
      demoProducts.firstWhere((p) => p.categoryId == 'phones').fulfillmentFields.map((f) => f.key),
      containsAll(['full_name', 'phone', 'address_line1', 'city']),
    );
    expect(
      validateDemoFulfillmentField(demoProducts.first.fulfillmentFields.single, '123'),
      isNotNull,
    );
    expect(
      validateDemoFulfillmentField(demoProducts.first.fulfillmentFields.single, '123456789'),
      isNull,
    );
    expect(
      validateDemoFulfillmentField(
        demoProducts.firstWhere((p) => p.categoryId == 'tactical').fulfillmentFields.single,
        'Bad Riot ID',
      ),
      isNotNull,
    );
  });

  testWidgets('redemption asks for details before deducting and persists them with the order', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await repo.createAccount('demo@example.com', 'Password123', 1);
    await tester.pumpWidget(
      DemoScope(
        repository: repo,
        child: MaterialApp(home: CategoryDetailsPage(category: demoCategories.first)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Redeem').first);
    await tester.tap(find.text('Redeem').first);
    await tester.pumpAndSettle();
    expect(find.text('Redemption details'), findsOneWidget);
    expect(repo.balance, 6000);
    expect(repo.orders, isEmpty);
    await tester.tap(find.text('Confirm redemption'));
    await tester.pump();
    expect(find.text('This field is required'), findsWidgets);
    await tester.enterText(find.byKey(const ValueKey('fulfillment-player_id')), '5123456789');
    await tester.enterText(
      find.byKey(const ValueKey('fulfillment-player_id-confirm')),
      '5123456789',
    );
    await tester.ensureVisible(find.text('Confirm redemption'));
    await tester.tap(find.text('Confirm redemption'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pumpAndSettle();
    expect(repo.balance, 4800);
    expect(repo.orders.single['fulfillmentDetails'], {'player_id': '5123456789'});
    expect(repo.orders.single['status'], contains('Demo order'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile unread badge follows repository read state', (tester) async {
    await repo.createAccount('demo@example.com', 'Password123', 9);
    tester.view.padding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(
      DemoScope(
        repository: repo,
        child: MaterialApp(
          home: Scaffold(body: ProfilePanel(onWallet: () {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('profile-unread-badge')), findsOneWidget);
    final art = imageAsset(
      'assets/Creative_Rewards_Assets/07_profile/profile_header_background.png',
    );
    expect(tester.getTopLeft(art).dy, 0);
    expect(imageAsset(characterAsset(9)), findsWidgets);
    await tester.runAsync(() => repo.readNotification(0));
    await tester.pump();
    expect(find.byKey(const ValueKey('profile-unread-badge')), findsNothing);
    await tester.runAsync(() => repo.enterGiveaway(demoGiveaways.first));
    await tester.pump();
    expect(find.byKey(const ValueKey('profile-unread-badge')), findsOneWidget);
    await tester.runAsync(() => repo.updateProfile('demo', 1));
    await tester.pump();
    expect(imageAsset(characterAsset(1)), findsWidgets);
  });

  testWidgets('ticket reveal shows only the repository number after animation timing', (
    tester,
  ) async {
    await repo.createAccount('demo@example.com', 'Password123', 1);
    final saved = await tester.runAsync(() => repo.enterGiveaway(demoGiveaways.first));
    await tester.pumpWidget(
      MaterialApp(
        home: NumberRevealPage(title: 'AirPods Pro', number: saved!),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('saved-ticket-number')), findsNothing);
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(saved), findsOneWidget);
    expect(repo.entries, hasLength(1));
  });
}
