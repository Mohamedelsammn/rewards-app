import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/di/injection.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/admin_dashboard/presentation/admin_shell.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';
import 'package:rewardsapp/services/cache/cache_service.dart';
import 'package:rewardsapp/shared/repositories/auth_repository.dart';
import 'package:rewardsapp/shared/repositories/giveaway_repository.dart';
import 'package:rewardsapp/shared/repositories/winner_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGiveawayRepository extends Mock implements GiveawayRepository {}

class MockWinnerRepository extends Mock implements WinnerRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCacheService extends Mock implements CacheService {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class _FakeRealtimeChannel extends Fake implements RealtimeChannel {}

const _adminUser = User(
  id: 'admin-1',
  appMetadata: {},
  userMetadata: {'full_name': 'Ali'},
  aud: 'authenticated',
  email: 'ali@example.com',
  createdAt: '2026-01-01T00:00:00Z',
);

/// Covers Section 7/9's "Admin bottom nav is now Home / Analysis / Profile,
/// using the exact same Liquid Glass component as User" requirement, and
/// re-confirms (with the real, current 3-tab AdminShell) that no page it
/// hosts throws the "No Material widget found" error.
void main() {
  setUpAll(() {
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(_FakeRealtimeChannel());
  });

  late MockGiveawayRepository giveawayRepository;
  late MockWinnerRepository winnerRepository;
  late MockSupabaseClient client;
  late MockGoTrueClient auth;

  setUp(() async {
    giveawayRepository = MockGiveawayRepository();
    winnerRepository = MockWinnerRepository();
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(_adminUser);
    when(
      () => giveawayRepository.getMyAdminGiveaways(),
    ).thenAnswer((_) async => const Result.success([]));
    when(() => giveawayRepository.giveawayCreated).thenAnswer((_) => const Stream.empty());
    when(() => winnerRepository.winnerSelected).thenAnswer((_) => const Stream.empty());

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

    await getIt.reset();
    getIt
      ..registerSingleton<SupabaseClient>(client)
      ..registerSingleton<GiveawayRepository>(giveawayRepository)
      ..registerSingleton<WinnerRepository>(winnerRepository)
      ..registerSingleton<AuthRepository>(MockAuthRepository())
      ..registerSingleton<CacheService>(MockCacheService());
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpAdminShell(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('ar')],
        home: AdminShell(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('has exactly 3 destinations: Dashboard, Analysis, Profile', (tester) async {
    await pumpAdminShell(tester);

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
    expect(find.byIcon(Icons.query_stats_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    // The old standalone Giveaways-listing destination is gone.
    expect(find.byIcon(Icons.list_alt_rounded), findsNothing);
  });

  testWidgets('switches to the Analysis tab without a Material-ancestor crash', (tester) async {
    await pumpAdminShell(tester);

    await tester.tap(find.byIcon(Icons.query_stats_outlined));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Empty state: getMyAdminGiveaways() was mocked to return no giveaways.
    expect(find.text('No giveaways yet — create one to see analysis here.'), findsOneWidget);
  });

  testWidgets('switches to the Profile tab (ListTile-based) without a Material-ancestor crash', (
    tester,
  ) async {
    await pumpAdminShell(tester);

    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Sign Out is a large primary-styled button (not a ListTile) -- see
    // admin_profile_page.dart's redesign; the Language row alongside it is
    // still ListTile-based, which is what this test's title refers to.
    expect(find.text('Sign Out'), findsOneWidget);
  });
}
