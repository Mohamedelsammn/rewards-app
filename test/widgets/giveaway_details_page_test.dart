import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/di/injection.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/giveaway_details/presentation/giveaway_details_page.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';
import 'package:rewardsapp/shared/models/giveaway.dart';
import 'package:rewardsapp/shared/widgets/app_network_image.dart';
import 'package:rewardsapp/shared/repositories/giveaway_repository.dart';
import 'package:rewardsapp/shared/repositories/participation_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGiveawayRepository extends Mock implements GiveawayRepository {}

class MockParticipationRepository extends Mock implements ParticipationRepository {}

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

Giveaway _giveaway({
  required String prizeDescription,
  required String descriptionRules,
  String? imageUrl,
}) =>
    Giveaway(
      id: 'g1',
      title: 'Win a Car',
      organizerName: 'Acme Co',
      prizeDescription: prizeDescription,
      descriptionRules: descriptionRules,
      imageUrl: imageUrl,
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 10),
      endTime: '18:00',
      status: GiveawayStatus.active,
      numberDigitWidth: 4,
      maxParticipants: null,
      participantCount: 5,
    );

/// Covers Phase 9: Prize Description and Giveaway Description & Rules are
/// optional at creation -- Giveaway Details must hide each section entirely
/// when blank (no empty box, no literal "null"), while a giveaway that has
/// them (the pre-existing case) keeps rendering exactly as before.
void main() {
  setUpAll(() {
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(_FakeRealtimeChannel());
  });

  late MockGiveawayRepository giveawayRepository;
  late MockParticipationRepository participationRepository;
  late MockSupabaseClient client;

  setUp(() async {
    giveawayRepository = MockGiveawayRepository();
    participationRepository = MockParticipationRepository();
    client = MockSupabaseClient();
    _stubRealtimeChannel(client);
    await getIt.reset();
    getIt
      ..registerSingleton<GiveawayRepository>(giveawayRepository)
      ..registerSingleton<ParticipationRepository>(participationRepository)
      ..registerSingleton<SupabaseClient>(client);

    when(
      () => giveawayRepository.getRequirements(any()),
    ).thenAnswer((_) async => const Result.success([]));
    when(
      () => participationRepository.getMyParticipationForGiveaway(any()),
    ).thenAnswer((_) async => const Result.success(null));
  });

  tearDown(() async => getIt.reset());

  Future<void> pumpDetails(
    WidgetTester tester,
    Giveaway giveaway, {
    Locale locale = const Locale('en'),
  }) async {
    when(
      () => giveawayRepository.getGiveawayById(giveaway.id, forceRefresh: false),
    ).thenAnswer((_) async => Result.success(giveaway));

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: GiveawayDetailsPage(giveawayId: giveaway.id, initialGiveaway: giveaway),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a giveaway with a prize description and rules shows both sections', (tester) async {
    await pumpDetails(
      tester,
      _giveaway(prizeDescription: 'A brand new car', descriptionRules: 'Must be 18+'),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('About this prize'), findsOneWidget);
    expect(find.text('A brand new car'), findsOneWidget);
    expect(find.text('Rules'), findsOneWidget);
    expect(find.text('Must be 18+'), findsOneWidget);
  });

  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets('giveaway hero preserves the full image in ${locale.languageCode}', (tester) async {
      await pumpDetails(
        tester,
        _giveaway(
          prizeDescription: '',
          descriptionRules: '',
          imageUrl: 'https://example.com/tall-product.png',
        ),
        locale: locale,
      );

      final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(image.fit, BoxFit.contain);
      expect(tester.getSize(find.byType(AppNetworkImage)).height, greaterThan(280));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a giveaway created without a prize description or rules hides both sections '
      'gracefully -- no empty box, no literal "null"', (tester) async {
    await pumpDetails(tester, _giveaway(prizeDescription: '', descriptionRules: ''));

    expect(tester.takeException(), isNull);
    expect(find.text('About this prize'), findsNothing);
    expect(find.text('Rules'), findsNothing);
    expect(find.textContaining('null'), findsNothing);
    // The rest of the page still renders fine.
    expect(find.text('Win a Car'), findsOneWidget);
  });
}
