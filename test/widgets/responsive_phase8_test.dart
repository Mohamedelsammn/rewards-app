import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/di/injection.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/core/localization/locale_controller.dart';
import 'package:rewardsapp/features/admin_auth/presentation/admin_auth_page.dart';
import 'package:rewardsapp/features/admin_settings/presentation/admin_profile_page.dart';
import 'package:rewardsapp/features/settings/presentation/edit_profile_page.dart';
import 'package:rewardsapp/features/settings/presentation/settings_page.dart';
import 'package:rewardsapp/features/user_home/presentation/user_home_page.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';
import 'package:rewardsapp/services/notification_service.dart';
import 'package:rewardsapp/services/secure_storage_service.dart';
import 'package:rewardsapp/shared/models/giveaway.dart';
import 'package:rewardsapp/shared/repositories/auth_repository.dart';
import 'package:rewardsapp/shared/repositories/giveaway_repository.dart';
import 'package:rewardsapp/shared/repositories/notification_repository.dart';
import 'package:rewardsapp/shared/repositories/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGiveawayRepository extends Mock implements GiveawayRepository {}

class MockNotificationRepository extends Mock implements NotificationRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class MockUserRepository extends Mock implements UserRepository {}

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

const _longName = 'Alexandria Katherine Featherington-Worthington the Third';

Giveaway _giveaway(int i) => Giveaway(
  id: 'g$i',
  title: 'A Very Long Prize Giveaway Title That Could Wrap $i',
  organizerName: 'International Consumer Electronics Retailers Alliance $i',
  prizeDescription: 'Prize $i',
  descriptionRules: 'Rules $i',
  imageUrl: null,
  startDate: DateTime(2026, 1, 1),
  endDate: DateTime(2026, 1, 10),
  endTime: '18:00',
  status: GiveawayStatus.active,
  numberDigitWidth: 4,
  maxParticipants: null,
  participantCount: i * 10,
);

/// Phase 8 responsiveness audit: a narrow (320dp) viewport and a large
/// accessibility text scale, applied to every screen touched by this pass.
/// No RenderFlex overflow, no clipped content -- these reproduce the exact
/// failure conditions against the real widgets.
Future<void> _pumpAtSize(
  WidgetTester tester,
  Widget child, {
  double width = 320,
  double height = 700,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  if (textScale != 1.0) {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: child,
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(_FakeRealtimeChannel());
  });

  group('UserHomePage on a 320dp screen with a large text scale', () {
    late MockGiveawayRepository giveawayRepository;
    late MockNotificationRepository notificationRepository;
    late MockSupabaseClient client;
    late MockSecureStorageService secureStorage;

    setUp(() async {
      giveawayRepository = MockGiveawayRepository();
      notificationRepository = MockNotificationRepository();
      client = MockSupabaseClient();
      secureStorage = MockSecureStorageService();
      _stubRealtimeChannel(client);
      when(() => secureStorage.cachedFullName).thenAnswer((_) async => null);
      when(() => secureStorage.identityChanged).thenAnswer((_) => const Stream.empty());
      await getIt.reset();
      getIt
        ..registerSingleton<GiveawayRepository>(giveawayRepository)
        ..registerSingleton<NotificationRepository>(notificationRepository)
        ..registerSingleton<SupabaseClient>(client)
        ..registerSingleton<SecureStorageService>(secureStorage);
    });

    tearDown(() async => getIt.reset());

    testWidgets(
      'renders the pinned search header and giveaway list with no overflow at 1.4x text scale',
      (tester) async {
        when(
          () => giveawayRepository.getBrowsePage(),
        ).thenAnswer((_) async => Result.success(List.generate(6, _giveaway)));
        when(
          () => notificationRepository.getUnreadCount(),
        ).thenAnswer((_) async => const Result.success(0));

        await _pumpAtSize(
          tester,
          const Scaffold(
            body: Material(type: MaterialType.transparency, child: UserHomePage()),
          ),
          textScale: 1.4,
        );
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(tester.takeException(), isNull);
      },
    );
  });

  group('SettingsPage on a 320dp screen', () {
    late MockSecureStorageService secureStorage;
    late MockNotificationService notificationService;

    setUp(() async {
      secureStorage = MockSecureStorageService();
      notificationService = MockNotificationService();
      when(() => secureStorage.identityChanged).thenAnswer((_) => const Stream.empty());
      await getIt.reset();
      getIt
        ..registerSingleton<SecureStorageService>(secureStorage)
        ..registerSingleton<NotificationService>(notificationService);
    });

    tearDown(() async => getIt.reset());

    testWidgets('a long registered profile name/phone does not overflow', (tester) async {
      when(() => secureStorage.cachedFullName).thenAnswer((_) async => _longName);
      when(() => secureStorage.cachedPhone).thenAnswer((_) async => '+12025550190123456');
      when(() => secureStorage.cachedCountryCode).thenAnswer((_) async => null);

      await _pumpAtSize(
        tester,
        const Scaffold(
          body: Material(type: MaterialType.transparency, child: SettingsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('AdminProfilePage on a 320dp screen', () {
    late MockSupabaseClient client;
    late MockGoTrueClient auth;
    late MockAuthRepository authRepository;
    late MockSecureStorageService secureStorage;

    setUp(() async {
      client = MockSupabaseClient();
      auth = MockGoTrueClient();
      authRepository = MockAuthRepository();
      secureStorage = MockSecureStorageService();
      when(() => client.auth).thenReturn(auth);
      when(() => auth.currentUser).thenReturn(
        User(
          id: 'admin-1',
          appMetadata: const {},
          userMetadata: {'full_name': _longName},
          aud: 'authenticated',
          email: 'a.very.long.administrator.email.address@example-organization.com',
          createdAt: '2026-01-01T00:00:00Z',
        ),
      );
      when(() => secureStorage.cachedLanguageCode).thenAnswer((_) async => null);

      await getIt.reset();
      getIt
        ..registerSingleton<SupabaseClient>(client)
        ..registerSingleton<AuthRepository>(authRepository)
        ..registerSingleton<SecureStorageService>(secureStorage)
        ..registerSingleton<LocaleController>(LocaleController(secureStorage));
    });

    tearDown(() async => getIt.reset());

    testWidgets('a long admin name/email does not overflow', (tester) async {
      await _pumpAtSize(
        tester,
        const Scaffold(
          body: Material(type: MaterialType.transparency, child: AdminProfilePage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('EditProfilePage on a 320dp screen', () {
    late MockSecureStorageService secureStorage;
    late MockUserRepository userRepository;

    setUp(() async {
      secureStorage = MockSecureStorageService();
      userRepository = MockUserRepository();
      when(() => secureStorage.cachedFullName).thenAnswer((_) async => _longName);
      when(() => secureStorage.cachedPhone).thenAnswer((_) async => '+12025550190123456');
      when(() => secureStorage.cachedCountryCode).thenAnswer((_) async => 'US');

      await getIt.reset();
      getIt
        ..registerSingleton<SecureStorageService>(secureStorage)
        ..registerSingleton<UserRepository>(userRepository);
    });

    tearDown(() async => getIt.reset());

    testWidgets('a long cached name/phone does not overflow', (tester) async {
      await _pumpAtSize(tester, const EditProfilePage(), textScale: 1.4);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('AdminAuthPage on a 320dp screen', () {
    late MockAuthRepository authRepository;

    setUp(() async {
      authRepository = MockAuthRepository();
      await getIt.reset();
      getIt.registerSingleton<AuthRepository>(authRepository);
    });

    tearDown(() async => getIt.reset());

    testWidgets('switching Sign In <-> Sign Up mid-animation does not overflow', (tester) async {
      await _pumpAtSize(tester, const AdminAuthPage());

      await tester.tap(find.text('Sign Up'));
      // Pump mid-animation (the transition is 320ms) -- this is exactly
      // where a height/overflow bug in the AnimatedSize/AnimatedSwitcher
      // combo would show up.
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.takeException(), isNull);

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Sign In'));
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('the WhatsApp contact section does not overflow at 1.4x text scale', (
      tester,
    ) async {
      await _pumpAtSize(tester, const AdminAuthPage(), textScale: 1.4);

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text("Don't have an Admin Access Code?"), findsOneWidget);
    });
  });
}
