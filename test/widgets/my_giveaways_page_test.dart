import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/di/injection.dart';
import 'package:rewardsapp/core/error/failure.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/giveaway_details/presentation/giveaway_details_page.dart';
import 'package:rewardsapp/features/my_giveaways/presentation/my_giveaways_page.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';
import 'package:rewardsapp/shared/models/participation.dart';
import 'package:rewardsapp/services/secure_storage_service.dart';
import 'package:rewardsapp/shared/repositories/giveaway_repository.dart';
import 'package:rewardsapp/shared/repositories/participation_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockParticipationRepository extends Mock implements ParticipationRepository {}

class MockGiveawayRepository extends Mock implements GiveawayRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class _FakeRealtimeChannel extends Fake implements RealtimeChannel {}

/// GiveawayDetailsCubit's realtime subscription just needs a channel it can
/// chain `.onPostgresChanges(...).subscribe()` on without throwing -- these
/// tests aren't exercising realtime behavior itself, so the fake is a no-op
/// that always returns itself.
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

/// Covers the USER My Giveaways card rewrite: the whole card must be
/// tappable and must open GiveawayDetailsPage for the EXACT giveaway it
/// represents, and a finished giveaway must keep showing (with the correct
/// winner/not-selected state) instead of disappearing once
/// giveaway.status != active.
void main() {
  setUpAll(() {
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(_FakeRealtimeChannel());
  });

  late MockParticipationRepository participationRepository;
  late MockGiveawayRepository giveawayRepository;
  late MockSupabaseClient client;
  late MockSecureStorageService secureStorage;

  setUp(() async {
    participationRepository = MockParticipationRepository();
    giveawayRepository = MockGiveawayRepository();
    client = MockSupabaseClient();
    secureStorage = MockSecureStorageService();
    _stubRealtimeChannel(client);
    when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-1');
    when(
      () => participationRepository.participationCreated,
    ).thenAnswer((_) => const Stream.empty());

    await getIt.reset();
    getIt
      ..registerSingleton<ParticipationRepository>(participationRepository)
      ..registerSingleton<GiveawayRepository>(giveawayRepository)
      ..registerSingleton<SupabaseClient>(client)
      ..registerSingleton<SecureStorageService>(secureStorage);

    // Stubs for whatever GiveawayDetailsPage loads once navigated to -- the
    // exact content isn't under test here, only that navigation landed on
    // the right page with the right id.
    when(
      () => giveawayRepository.getGiveawayById(any(), forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer((_) async => const Result.failure(NetworkFailure()));
    when(
      () => giveawayRepository.getRequirements(any()),
    ).thenAnswer((_) async => const Result.success([]));
    when(
      () => participationRepository.getMyParticipationForGiveaway(any()),
    ).thenAnswer((_) async => const Result.success(null));
  });

  tearDown(() async => getIt.reset());

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('ar')],
        home: Scaffold(
          body: Material(type: MaterialType.transparency, child: MyGiveawaysPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Participation buildParticipation({required bool ended, required bool isWinner}) => Participation(
    id: 'p1',
    giveawayId: 'giveaway-42',
    participationSequence: 1,
    participationNumber: 7,
    scratchRevealedAt: null,
    createdAt: DateTime(2026, 1, 1),
    giveaway: {
      'title': 'Win an iPhone',
      'image_url': null,
      'status': ended ? 'ended' : 'active',
      'organizer_name': 'Acme Co',
    },
    isWinner: isWinner,
  );

  testWidgets('tapping anywhere on the card opens GiveawayDetailsPage for that exact giveaway id', (
    tester,
  ) async {
    when(
      () => participationRepository.getMyParticipations(forceRefresh: true),
    ).thenAnswer((_) async => Result.success([buildParticipation(ended: false, isWinner: false)]));

    await pumpPage(tester);

    await tester.tap(find.text('Win an iPhone'));
    await tester.pumpAndSettle();

    expect(find.byType(GiveawayDetailsPage), findsOneWidget);
    final page = tester.widget<GiveawayDetailsPage>(find.byType(GiveawayDetailsPage));
    expect(page.giveawayId, 'giveaway-42');
  });

  testWidgets('an active giveaway shows the Active badge and no finished-state banner', (
    tester,
  ) async {
    when(
      () => participationRepository.getMyParticipations(forceRefresh: true),
    ).thenAnswer((_) async => Result.success([buildParticipation(ended: false, isWinner: false)]));

    await pumpPage(tester);

    expect(find.text('Active'), findsOneWidget);
    expect(find.text('You Won This Giveaway!'), findsNothing);
    expect(find.text('Not selected as the winner this time'), findsNothing);
  });

  testWidgets('a finished giveaway the user won stays visible and shows the winner state', (
    tester,
  ) async {
    when(
      () => participationRepository.getMyParticipations(forceRefresh: true),
    ).thenAnswer((_) async => Result.success([buildParticipation(ended: true, isWinner: true)]));

    await pumpPage(tester);

    expect(find.text('Win an iPhone'), findsOneWidget);
    expect(find.text('You Won This Giveaway!'), findsOneWidget);
  });

  testWidgets('a finished giveaway the user did NOT win stays visible (not hidden just because '
      'status != active) and shows the not-selected state', (tester) async {
    when(
      () => participationRepository.getMyParticipations(forceRefresh: true),
    ).thenAnswer((_) async => Result.success([buildParticipation(ended: true, isWinner: false)]));

    await pumpPage(tester);

    expect(find.text('Win an iPhone'), findsOneWidget);
    expect(find.text('Not selected as the winner this time'), findsOneWidget);
  });
}
