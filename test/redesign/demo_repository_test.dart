import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/localization/locale_controller.dart';
import 'package:rewardsapp/redesign/demo_repository.dart';
import 'package:rewardsapp/redesign/redesign_app.dart';
import 'package:rewardsapp/services/secure_storage_service.dart';

class MockBox extends Mock implements Box<dynamic> {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockBox box;
  late MockSecureStorage secure;
  late Map<dynamic, dynamic> data;
  late Map<String, String> secrets;
  late LocalRewardsRepository repository;

  setUp(() {
    box = MockBox();
    secure = MockSecureStorage();
    data = {};
    secrets = {};
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
    repository = LocalRewardsRepository(box, secure);
  });

  test('redemption updates balance and order history together, rejects overspend', () async {
    await repository.createAccount('Demo@Example.com', 'Password123', 3);
    expect(repository.balance, 6000);
    expect(repository.character, 3);

    expect(await repository.redeem(demoProducts.first), isTrue);
    expect(repository.balance, 4800);
    expect(repository.orders.single['title'], '60 UC');
    expect(await repository.redeem(demoProducts[3]), isFalse);
    expect(repository.orders.length, 1);
    expect(repository.balance, 4800);
  });

  test('concurrent redemption requests cannot spend the same points twice', () async {
    await repository.createAccount('demo@example.com', 'Password123', 1);
    final results = await Future.wait([
      repository.redeem(demoProducts[2]),
      repository.redeem(demoProducts[2]),
    ]);
    expect(results, [true, false]);
    expect(repository.balance, 500);
    expect(repository.orders, hasLength(1));
  });

  test('giveaway entry remains separate from points and is idempotent', () async {
    await repository.createAccount('demo@example.com', 'Password123', 1);
    final first = await repository.enterGiveaway(demoGiveaways.first);
    final repeat = await repository.enterGiveaway(demoGiveaways.first);
    expect(first, matches(RegExp(r'^\d{6}$')));
    expect(repeat, first);
    expect(repository.entries.length, 1);
    expect(repository.balance, 6000);
  });

  test('session restores and logout blocks restoration', () async {
    await repository.createAccount('demo@example.com', 'Password123', 1);
    final restored = LocalRewardsRepository(box, secure);
    expect(await restored.restore(), isTrue);
    expect(restored.email, 'demo@example.com');
    await restored.logout();
    expect(await LocalRewardsRepository(box, secure).restore(), isFalse);
  });

  test('existing demo account is detected without entering signup', () async {
    await repository.createAccount('demo@example.com', 'Password123', 1);
    expect(await repository.accountExists(' DEMO@example.com '), isTrue);
    expect(await repository.accountExists('new@example.com'), isFalse);
  });

  test('password strength requires length, mixed case, and a number', () {
    expect(passwordHasLettersAndNumbers('password123'), isTrue);
    expect(passwordIsStrong('password123'), isFalse);
    expect(passwordIsStrong('Password123'), isTrue);
  });

  test('unfinished signup stage survives restart and clears on account creation', () async {
    await repository.saveOnboarding(' Demo@Example.com ', 1);
    final restarted = LocalRewardsRepository(box, secure);
    expect(restarted.pendingEmail, 'demo@example.com');
    expect(restarted.pendingStage, 1);
    await restarted.saveOnboarding('demo@example.com', 2);
    expect(repository.pendingStage, 2);
    await restarted.createAccount('demo@example.com', 'Password123', 1);
    expect(repository.pendingEmail, isNull);
    expect(repository.pendingStage, 0);
  });

  testWidgets('splash resumes an interrupted signup at password entry', (tester) async {
    await repository.saveOnboarding('demo@example.com', 2);
    await tester.pumpWidget(
      DemoScope(
        repository: repository,
        child: const MaterialApp(home: DemoSplash()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('Create a password'), findsOneWidget);
  });

  testWidgets('main demo tabs navigate without overflow at 320 dp', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await repository.createAccount('demo@example.com', 'Password123', 1);
    await tester.pumpWidget(
      DemoScope(
        repository: repository,
        child: const MaterialApp(home: DemoShell()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your Points'), findsOneWidget);
    await tester.tap(find.text('Categories').last);
    await tester.pumpAndSettle();
    expect(find.byType(CategoryArtwork), findsWidgets);
    await tester.tap(find.text('Wallet').last);
    await tester.pumpAndSettle();
    expect(find.text('6000'), findsWidgets);
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('demo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('category group selector filters products without a selection checkmark', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      DemoScope(
        repository: repository,
        child: MaterialApp(home: CategoryDetailsPage(category: demoCategories.first)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('UC Top-Ups'), findsWidgets);
    expect(find.text('60 UC'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    await tester.tap(find.text('Items & Skins').first);
    await tester.pumpAndSettle();
    expect(find.text('Hero Outfit'), findsOneWidget);
    expect(find.text('60 UC'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home and wallet notification badges follow repository unread state', (tester) async {
    await repository.createAccount('demo@example.com', 'Password123', 1);
    await tester.pumpWidget(
      DemoScope(
        repository: repository,
        child: const MaterialApp(home: DemoShell()),
      ),
    );
    await tester.pumpAndSettle();
    Finder badgeText() =>
        find.descendant(of: find.byType(UnreadNotificationButton), matching: find.text('1'));
    expect(badgeText(), findsOneWidget);
    await tester.tap(find.text('Wallet').last);
    await tester.pumpAndSettle();
    expect(badgeText(), findsOneWidget);
    await repository.readNotification(0);
    await tester.pumpAndSettle();
    expect(badgeText(), findsNothing);
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(badgeText(), findsNothing);
  });

  testWidgets('pasted six-digit OTP advances registration in demo', (tester) async {
    await tester.pumpWidget(
      DemoScope(
        repository: repository,
        child: const MaterialApp(home: OtpPage(email: 'demo@example.com')),
      ),
    );
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    expect(find.text('Create a password'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('OTP Continue works after returning from password', (tester) async {
    await tester.pumpWidget(
      DemoScope(
        repository: repository,
        child: const MaterialApp(home: OtpPage(email: 'demo@example.com')),
      ),
    );
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    expect(find.text('Create a password'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Create a password'), findsOneWidget);
  });

  testWidgets('existing email offers login before OTP', (tester) async {
    await repository.createAccount('demo@example.com', 'Password123', 1);
    await tester.pumpWidget(
      DemoScope(
        repository: repository,
        child: const MaterialApp(home: EmailPage()),
      ),
    );
    await tester.enterText(find.byType(TextField), 'demo@example.com');
    await tester.tap(find.text('Send Code'));
    await tester.pumpAndSettle();
    expect(find.text('This email already has an account.'), findsOneWidget);
    expect(find.text('Log in instead'), findsOneWidget);
    expect(find.text('Check your email'), findsNothing);
  });

  testWidgets('welcome fits a compact 360 by 640 viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: WelcomePage()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(360, 808), const Size(393, 852)]) {
    testWidgets('home header fits $size without overflow', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await repository.createAccount('demo@example.com', 'Password123', 1);
      await tester.pumpWidget(
        DemoScope(
          repository: repository,
          child: const MaterialApp(home: DemoShell()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Your Points'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('profile language sheet updates locale without losing the session', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await repository.createAccount('demo@example.com', 'Password123', 8);
    final locale = LocaleController(SecureStorageService(secure));
    await locale.setLocale(const Locale('en'));
    await tester.pumpWidget(RedesignApp(repository: repository, localeController: locale));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Edit Profile'), findsNothing);
    await tester.ensureVisible(find.text('Language'));
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    expect(find.text('Choose Language'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('language-ar')));
    await tester.pumpAndSettle();
    expect(locale.value.languageCode, 'ar');
    expect(repository.email, 'demo@example.com');
    expect(find.text('اللغة'), findsWidgets);
  });

  testWidgets('sign out requires confirmation and cancellation keeps the session', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await repository.createAccount('demo@example.com', 'Password123', 1);
    await tester.pumpWidget(
      DemoScope(
        repository: repository,
        child: const MaterialApp(home: DemoShell()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(200, 650), const Offset(0, -550));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-sign-out')));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.email, 'demo@example.com');
    await tester.tap(find.byKey(const ValueKey('profile-sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Out').last);
    await tester.pumpAndSettle();
    expect(repository.email, isNull);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('login fields remain usable with the keyboard on a compact viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await repository.createAccount('demo@example.com', 'Password123', 1);
    await repository.logout();
    await tester.pumpWidget(
      DemoScope(
        repository: repository,
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.first, 'demo@example.com');
    await tester.enterText(fields.last, 'Password123');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byTooltip('Show password'));
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('order filters do not classify demo orders as shipped', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 808));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await repository.createAccount('demo@example.com', 'Password123', 1);
    await tester.runAsync(() => repository.redeem(demoProducts[1]));
    await tester.pumpWidget(
      DemoScope(
        repository: repository,
        child: const MaterialApp(home: OrdersPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopRight(find.byKey(const ValueKey('order-filter-Delivered'))).dx,
      lessThan(360),
    );
    expect(find.text('180 UC'), findsOneWidget);
    expect(find.text('Demo order'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('order-filter-Shipped')));
    await tester.pumpAndSettle();
    expect(find.text('180 UC'), findsNothing);
    expect(find.text('No Shipped orders'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('order-filter-All')));
    await tester.pumpAndSettle();
    expect(find.text('180 UC'), findsOneWidget);
  });

  testWidgets('giveaway card navigates with the repository ticket number', (tester) async {
    await repository.createAccount('demo@example.com', 'Password123', 1);
    final number = await tester.runAsync(() => repository.enterGiveaway(demoGiveaways.first));
    await tester.pumpWidget(
      DemoScope(
        repository: repository,
        child: const MaterialApp(home: MyGiveawaysPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(number!), findsOneWidget);
    await tester.tap(find.text('AirPods Pro'));
    await tester.pumpAndSettle();
    expect(find.text(number), findsOneWidget);
  });
}
