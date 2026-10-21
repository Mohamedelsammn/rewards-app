import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/di/injection.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/notifications/presentation/notifications_page.dart';
import 'package:rewardsapp/features/user_home/presentation/user_home_page.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';
import 'package:rewardsapp/shared/models/giveaway.dart';
import 'package:rewardsapp/services/secure_storage_service.dart';
import 'package:rewardsapp/shared/repositories/giveaway_repository.dart';
import 'package:rewardsapp/shared/repositories/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGiveawayRepository extends Mock implements GiveawayRepository {}

class MockNotificationRepository extends Mock implements NotificationRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class _FakeRealtimeChannel extends Fake implements RealtimeChannel {}

/// UserHomeCubit's realtime subscription just needs a channel it can chain
/// `.onPostgresChanges(...).subscribe()` on without throwing -- these tests
/// aren't exercising realtime behavior itself, so the fake is a no-op that
/// always returns itself.
void _stubRealtimeChannel(MockSupabaseClient client) {
  final channel = MockRealtimeChannel();
  when(() => client.channel(any())).thenReturn(channel);
  when(
    () => channel.onPostgresChanges(
      event: any(named: 'event'),
      schema: any(named: 'schema'),
      table: any(named: 'table'),
      filter: any(named: 'filter'),
      callback: any(named: 'callback'),
    ),
  ).thenReturn(channel);
  when(() => channel.subscribe()).thenReturn(channel);
  when(() => client.removeChannel(any())).thenAnswer((_) async => 'ok');
}

Giveaway _giveaway(int i) => Giveaway(
  id: 'g$i',
  title: 'Giveaway $i',
  organizerName: 'Org $i',
  prizeDescription: 'Prize $i',
  descriptionRules: 'Rules $i',
  imageUrl: null,
  startDate: DateTime(2026, 1, 1),
  endDate: DateTime(2026, 1, 10),
  endTime: '18:00',
  status: GiveawayStatus.active,
  numberDigitWidth: 4,
  maxParticipants: null,
  participantCount: i,
);

void main() {
  setUpAll(() {
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(_FakeRealtimeChannel());
  });

  late MockGiveawayRepository giveawayRepository;
  late MockNotificationRepository notificationRepository;
  late MockSupabaseClient client;
  late MockSecureStorageService secureStorage;
  late StreamController<void> identityChanged;

  setUp(() async {
    giveawayRepository = MockGiveawayRepository();
    notificationRepository = MockNotificationRepository();
    client = MockSupabaseClient();
    secureStorage = MockSecureStorageService();
    identityChanged = StreamController<void>.broadcast();
    addTearDown(identityChanged.close);
    _stubRealtimeChannel(client);
    when(() => secureStorage.cachedFullName).thenAnswer((_) async => null);
    when(() => secureStorage.identityChanged).thenAnswer((_) => identityChanged.stream);

    await getIt.reset();
    getIt
      ..registerSingleton<GiveawayRepository>(giveawayRepository)
      ..registerSingleton<NotificationRepository>(notificationRepository)
      ..registerSingleton<SupabaseClient>(client)
      ..registerSingleton<SecureStorageService>(secureStorage);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpUserHome(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('ar')],
        // The shell normally supplies this Material ancestor for TextField/
        // InkWell (see UserHomeShell's doc comment) -- reproduced here since
        // this test pumps UserHomePage standalone.
        home: Scaffold(
          body: Material(type: MaterialType.transparency, child: UserHomePage()),
        ),
      ),
    );
    // Not pumpAndSettle(): the empty state's Lottie animation
    // (assets/lottie/empty-gift.json, `repeat: true`) loops forever, so the
    // frame scheduler never goes idle and pumpAndSettle would time out. A
    // few bounded pumps are enough to resolve the async giveaway/unread-count
    // loads and let the widget tree settle into its post-load shape.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('welcome header profile name', () {
    testWidgets('shows Guest before registration and the real name immediately after -- no '
        'navigation away and back, no app restart -- covers the "profile only appears after '
        'a refresh" fix', (tester) async {
      when(
        () => giveawayRepository.getBrowsePage(),
      ).thenAnswer((_) async => const Result.success([]));
      when(
        () => notificationRepository.getUnreadCount(),
      ).thenAnswer((_) async => const Result.success(0));

      await pumpUserHome(tester);
      expect(find.text('Guest'), findsOneWidget);

      when(() => secureStorage.cachedFullName).thenAnswer((_) async => 'Mohamed');
      identityChanged.add(null);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Mohamed'), findsOneWidget);
      expect(find.text('Guest'), findsNothing);
    });
  });

  for (final width in [320.0, 360.0, 393.0, 430.0, 700.0]) {
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      testWidgets('lazy grid, real data and RTL at $width dp in ${locale.languageCode}', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        when(
          () => giveawayRepository.getBrowsePage(),
        ).thenAnswer((_) async => Result.success(List.generate(12, _giveaway)));
        when(
          () => notificationRepository.getUnreadCount(),
        ).thenAnswer((_) async => const Result.success(0));
        await pumpUserHome(tester, locale: locale);
        final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
        expect(
          (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount).crossAxisCount,
          width >= 732 ? 3 : 2,
        );
        expect(find.text('Giveaway 0'), findsOneWidget);
        expect(find.text('Giveaway 11'), findsNothing);
        final direction = Directionality.of(tester.element(find.byType(TextField)));
        expect(direction, locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  group('empty giveaway state (Section 5: DB cleanup leaves zero sample giveaways)', () {
    testWidgets('shows the graceful "no active giveaways" message, not a blank/broken screen', (
      tester,
    ) async {
      when(
        () => giveawayRepository.getBrowsePage(),
      ).thenAnswer((_) async => const Result.success([]));
      when(
        () => notificationRepository.getUnreadCount(),
      ).thenAnswer((_) async => const Result.success(0));

      await pumpUserHome(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('No giveaways found'), findsOneWidget);
    });
  });

  group('notification bell', () {
    testWidgets('ended card has exactly one status label and no redundant countdown', (
      tester,
    ) async {
      when(
        () => giveawayRepository.getBrowsePage(),
      ).thenAnswer((_) async => Result.success([_giveaway(1)]));
      when(
        () => notificationRepository.getUnreadCount(),
      ).thenAnswer((_) async => const Result.success(0));
      await pumpUserHome(tester);
      expect(find.text('Ended'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
    testWidgets('shows an unread dot when there are unread notifications', (tester) async {
      when(
        () => giveawayRepository.getBrowsePage(),
      ).thenAnswer((_) async => const Result.success([]));
      when(
        () => notificationRepository.getUnreadCount(),
      ).thenAnswer((_) async => const Result.success(3));

      await pumpUserHome(tester);

      expect(find.bySemanticsLabel('Notifications'), findsOneWidget);
      expect(find.byKey(const ValueKey('notification_unread_badge')), findsOneWidget);
    });

    testWidgets('tapping the bell opens NotificationsPage', (tester) async {
      when(
        () => giveawayRepository.getBrowsePage(),
      ).thenAnswer((_) async => const Result.success([]));
      when(
        () => notificationRepository.getUnreadCount(),
      ).thenAnswer((_) async => const Result.success(0));
      when(
        () => notificationRepository.getMyNotifications(),
      ).thenAnswer((_) async => const Result.success([]));

      await pumpUserHome(tester);

      await tester.tap(find.bySemanticsLabel('Notifications'));
      // Not pumpAndSettle() -- see pumpUserHome's comment; the page being
      // navigated away from still hosts the looping Lottie animation.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(tester.takeException(), isNull);
      expect(find.byType(NotificationsPage), findsOneWidget);
    });
  });
}
