import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/di/injection.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/admin_dashboard/presentation/admin_dashboard_page.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';
import 'package:rewardsapp/shared/models/giveaway.dart';
import 'package:rewardsapp/shared/repositories/giveaway_repository.dart';
import 'package:rewardsapp/shared/repositories/winner_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGiveawayRepository extends Mock implements GiveawayRepository {}

class MockWinnerRepository extends Mock implements WinnerRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class _FakeRealtimeChannel extends Fake implements RealtimeChannel {}

const _adminUser = User(
  id: 'admin-1',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

Giveaway _giveaway(String id, GiveawayStatus status) {
  final now = DateTime.now().toUtc();
  final startsAt = status == GiveawayStatus.ended
      ? now.subtract(const Duration(days: 10))
      : now.subtract(const Duration(days: 1));
  final endsAt = status == GiveawayStatus.ended
      ? now.subtract(const Duration(days: 1))
      : now.add(const Duration(days: 5));
  return Giveaway(
    id: id,
    title: 'Prize $id',
    organizerName: 'Org',
    prizeDescription: 'Prize',
    descriptionRules: 'Rules',
    imageUrl: null,
    startDate: startsAt,
    endDate: endsAt,
    endTime: '18:00',
    status: status,
    numberDigitWidth: 4,
    maxParticipants: null,
    participantCount: 3,
    startsAtUtc: startsAt,
    endsAtUtc: endsAt,
  );
}

/// Covers "a giveaway must not disappear from Admin Home once it ends" --
/// see docs/fixes/state-sync-and-session-restoration.md, Bug 3.
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
      ..registerSingleton<GiveawayRepository>(giveawayRepository)
      ..registerSingleton<WinnerRepository>(winnerRepository)
      ..registerSingleton<SupabaseClient>(client);
  });

  tearDown(() async => getIt.reset());

  Future<void> pumpDashboard(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    // Tall enough that both the Active and Ended Campaigns sections fit
    // without needing to scroll a lazily-built ListView into view first.
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
        home: Scaffold(body: AdminDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an ended giveaway still renders its own card in an Ended Campaigns section', (
    tester,
  ) async {
    when(() => giveawayRepository.getMyAdminGiveaways()).thenAnswer(
      (_) async => Result.success([
        _giveaway('g-active', GiveawayStatus.active),
        _giveaway('g-ended', GiveawayStatus.ended),
      ]),
    );

    await pumpDashboard(tester);

    expect(find.text('Prize g-active'), findsOneWidget);
    expect(find.text('Prize g-ended'), findsOneWidget);
    // Both remain reachable via the same "View Analytics" entry point.
    expect(find.text('View Analytics'), findsNWidgets(2));
  });

  testWidgets('no Ended Campaigns section renders when nothing has ended yet', (tester) async {
    when(
      () => giveawayRepository.getMyAdminGiveaways(),
    ).thenAnswer((_) async => Result.success([_giveaway('g-active', GiveawayStatus.active)]));

    await pumpDashboard(tester);

    expect(find.text('Prize g-active'), findsOneWidget);
    expect(find.text('Prize g-ended'), findsNothing);
  });

  testWidgets('Arabic dashboard filters and empty state use valid Arabic localization', (
    tester,
  ) async {
    when(
      () => giveawayRepository.getMyAdminGiveaways(),
    ).thenAnswer((_) async => const Result.success([]));

    await pumpDashboard(tester, locale: const Locale('ar'));

    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('لا توجد مسابقات ضمن هذه المجموعة حاليًا.'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) => widget is Text && (widget.data ?? '').contains('????')),
      findsNothing,
    );
    expect(Directionality.of(tester.element(find.text('الكل'))), TextDirection.rtl);
  });
}
