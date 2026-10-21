import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/di/injection.dart';
import 'package:rewardsapp/core/error/failure.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/giveaway_analytics/presentation/bloc/giveaway_analytics_cubit.dart';
import 'package:rewardsapp/features/giveaway_analytics/presentation/giveaway_analytics_page.dart';
import 'package:rewardsapp/features/giveaway_analytics/presentation/widgets/view_winners_button.dart';
import 'package:rewardsapp/features/giveaway_analytics/presentation/widgets/winner_wheel_overlay.dart';
import 'package:rewardsapp/features/giveaway_analytics/presentation/widgets/winners_page.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';
import 'package:rewardsapp/shared/models/eligible_participant.dart';
import 'package:rewardsapp/shared/models/giveaway.dart';
import 'package:rewardsapp/shared/models/winner.dart';
import 'package:rewardsapp/shared/repositories/giveaway_repository.dart';
import 'package:rewardsapp/shared/repositories/storage_repository.dart';
import 'package:rewardsapp/shared/repositories/winner_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGiveawayRepository extends Mock implements GiveawayRepository {}

class MockWinnerRepository extends Mock implements WinnerRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockStorageRepository extends Mock implements StorageRepository {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class _FakeRealtimeChannel extends Fake implements RealtimeChannel {}

final _giveaway = Giveaway(
  id: 'g1',
  title: 'Win a Car',
  organizerName: 'Acme Co',
  prizeDescription: 'A car',
  descriptionRules: 'Rules',
  imageUrl: null,
  startDate: DateTime(2026, 1, 1),
  endDate: DateTime(2026, 1, 10),
  endTime: '18:00',
  status: GiveawayStatus.active,
  numberDigitWidth: 4,
  maxParticipants: null,
  participantCount: 3,
);

final _alice = EligibleParticipant(
  participationId: 'p-alice',
  participationNumber: 1111,
  fullName: 'Alice QA',
  createdAt: DateTime(2026, 1, 1),
  phoneE164: '+12025550101',
);

/// Covers the wheel-of-fortune feature's Admin-side entry points: the
/// normal "Select Winner" button must remain random by default, and the
/// top-bar picker only ever sets a PENDING manual target -- never selects a
/// winner directly, and never shows any visible "Manual Targeting" UI (the
/// admin should only be able to infer the target from the wheel result).
/// Both paths ultimately hand off to [WinnerWheelOverlay], shown as an
/// overlay on top of this same page (never a pushed route), which is what
/// actually calls [WinnerRepository.selectWinner].
void main() {
  setUpAll(() {
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(_FakeRealtimeChannel());
  });

  late MockGiveawayRepository giveawayRepository;
  late MockWinnerRepository winnerRepository;
  late MockSupabaseClient client;
  late MockStorageRepository storageRepository;

  setUp(() async {
    giveawayRepository = MockGiveawayRepository();
    winnerRepository = MockWinnerRepository();
    client = MockSupabaseClient();
    storageRepository = MockStorageRepository();
    when(() => storageRepository.deleteGiveawayImage(any())).thenAnswer((_) async {});

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

    // load()'s own raw participants/growth-chart query is out of scope for
    // this test -- forcing it to throw exercises the cubit's existing
    // graceful-degradation branch (still shows the giveaway + button, just
    // without the Recent Participants list), so the picker/wheel entry
    // points can be tested without mocking that whole postgrest chain.
    when(() => client.from(any())).thenThrow(Exception('not needed for this test'));

    when(
      () => giveawayRepository.getGiveawayById('g1', forceRefresh: true),
    ).thenAnswer((_) async => Result.success(_giveaway));

    await getIt.reset();
    getIt
      ..registerSingleton<GiveawayRepository>(giveawayRepository)
      ..registerSingleton<WinnerRepository>(winnerRepository)
      ..registerSingleton<SupabaseClient>(client)
      ..registerSingleton<StorageRepository>(storageRepository);
  });

  tearDown(() async => getIt.reset());

  Future<void> pumpAnalytics(WidgetTester tester) async {
    // Tall enough that the whole page (image, stats, chart, button) fits
    // without needing to scroll a lazily-built ListView into view first.
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('ar')],
        home: GiveawayAnalyticsPage(giveawayId: 'g1'),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('manual participant picker (top app bar)', () {
    testWidgets(
      'opens from the top-bar icon, showing the four-digit code, never "Ticket #1"',
      (tester) async {
        when(
          () => winnerRepository.getEligibleParticipants('g1'),
        ).thenAnswer((_) async => Result.success([_alice]));

        await pumpAnalytics(tester);
        await tester.tap(find.byIcon(Icons.tune_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Select a Participant'), findsOneWidget);
        expect(find.text('1111'), findsOneWidget);
        expect(find.text('Alice QA'), findsOneWidget);
        expect(find.textContaining('Ticket'), findsNothing);
      },
    );

    testWidgets(
      'choosing a participant only marks them as pending -- it does NOT call selectWinner, '
      'does NOT open the wheel, and shows NO visible "Manual Targeting" indication anywhere '
      'on the page (the admin should only be able to infer the target from the wheel result)',
      (tester) async {
        when(
          () => winnerRepository.getEligibleParticipants('g1'),
        ).thenAnswer((_) async => Result.success([_alice]));

        await pumpAnalytics(tester);
        await tester.tap(find.byIcon(Icons.tune_rounded));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Alice QA'));
        await tester.pumpAndSettle();

        verifyNever(
          () => winnerRepository.selectWinner(
            giveawayId: any(named: 'giveawayId'),
            participationId: any(named: 'participationId'),
            rank: any(named: 'rank'),
          ),
        );
        expect(find.byType(WinnerWheelOverlay), findsNothing);
        // Nothing on the main page reveals the pending manual target.
        expect(find.textContaining('1111'), findsNothing);
        expect(find.textContaining('Alice QA'), findsNothing);
        expect(find.textContaining('Manual'), findsNothing);
        // The pending target is still tracked internally -- just not shown.
        final cubit = tester.element(find.byIcon(Icons.tune_rounded)).read<GiveawayAnalyticsCubit>();
        expect(cubit.state.manualTarget, _alice);
      },
    );

    testWidgets('shows a clean message when there are no eligible participants left', (
      tester,
    ) async {
      when(
        () => winnerRepository.getEligibleParticipants('g1'),
      ).thenAnswer((_) async => const Result.success([]));

      await pumpAnalytics(tester);
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Every participant has already won.'), findsOneWidget);
    });
  });

  group('Select Winner button', () {
    testWidgets('with no pending target, opens the wheel and selects randomly '
        '(participationId omitted)', (tester) async {
      when(
        () => winnerRepository.selectWinner(giveawayId: 'g1', participationId: null, rank: 1),
      ).thenAnswer(
        (_) async => Result.success(
          Winner(
            id: 'w1',
            giveawayId: 'g1',
            participationId: 'p-random',
            rank: 1,
            selectedAt: DateTime(2026, 1, 2),
            celebrationAcknowledgedAt: null,
            participationNumber: 4821,
            fullName: 'Random Person',
          ),
        ),
      );

      await pumpAnalytics(tester);
      final navigator = Navigator.of(tester.element(find.text('Select Winner')));
      await tester.tap(find.text('Select Winner'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      // pumpAndSettle() stops once no more FRAMES are scheduled, which
      // doesn't wait for a bare Future.delayed (the wheel's post-spin pause
      // before transitioning to the reveal phase) that isn't itself driving
      // an animation -- flush it explicitly so no timer is left dangling at
      // teardown.
      await tester.pump(const Duration(milliseconds: 400));

      // Shown as an overlay on top of this same page -- never a pushed
      // route (single-route MaterialApp, so Navigator.canPop stays false)
      // -- with the Analytics content still mounted/visible behind it.
      expect(find.byType(WinnerWheelOverlay), findsOneWidget);
      expect(navigator.canPop(), isFalse);
      expect(find.text('Win a Car'), findsOneWidget);
      verify(
        () => winnerRepository.selectWinner(giveawayId: 'g1', participationId: null, rank: 1),
      ).called(1);
    });

    testWidgets(
      'with a pending manual target, opens the wheel and selects exactly that participant',
      (tester) async {
        when(
          () => winnerRepository.getEligibleParticipants('g1'),
        ).thenAnswer((_) async => Result.success([_alice]));
        when(
          () => winnerRepository.selectWinner(
            giveawayId: 'g1',
            participationId: 'p-alice',
            rank: 1,
          ),
        ).thenAnswer(
          (_) async => Result.success(
            Winner(
              id: 'w1',
              giveawayId: 'g1',
              participationId: 'p-alice',
              rank: 1,
              selectedAt: DateTime(2026, 1, 2),
              celebrationAcknowledgedAt: null,
              participationNumber: 1111,
              fullName: 'Alice QA',
            ),
          ),
        );

        await pumpAnalytics(tester);
        await tester.tap(find.byIcon(Icons.tune_rounded));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Alice QA'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Select Winner'));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(WinnerWheelOverlay), findsOneWidget);
        verify(
          () => winnerRepository.selectWinner(
            giveawayId: 'g1',
            participationId: 'p-alice',
            rank: 1,
          ),
        ).called(1);
      },
    );

    testWidgets(
      'the full wheel sequence eventually reveals the actual winner returned by the server',
      (tester) async {
        when(
          () => winnerRepository.selectWinner(giveawayId: 'g1', participationId: null, rank: 1),
        ).thenAnswer(
          (_) async => Result.success(
            Winner(
              id: 'w1',
              giveawayId: 'g1',
              participationId: 'p-random',
              rank: 1,
              selectedAt: DateTime(2026, 1, 2),
              celebrationAcknowledgedAt: null,
              participationNumber: 4821,
              fullName: 'Random Person',
            ),
          ),
        );

        await pumpAnalytics(tester);
        await tester.tap(find.text('Select Winner'));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));

        // Wheel spin (4200ms) + reveal-phase pause/animation.
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.text('4821'), findsOneWidget);
        expect(find.text('Random Person'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'a failed selection shows the overlay error view, and dismissing it closes the overlay '
      'cleanly without ever showing a winner',
      (tester) async {
        when(
          () => winnerRepository.selectWinner(giveawayId: 'g1', participationId: null, rank: 1),
        ).thenAnswer(
          (_) async => const Result.failure(ValidationFailure('no_eligible_participants')),
        );

        await pumpAnalytics(tester);
        await tester.tap(find.text('Select Winner'));
        await tester.pumpAndSettle();

        expect(find.byType(WinnerWheelOverlay), findsOneWidget);
        expect(find.text('Random Person'), findsNothing);
        expect(find.textContaining('4821'), findsNothing);

        await tester.tap(find.text('Dismiss'));
        await tester.pumpAndSettle();

        expect(find.byType(WinnerWheelOverlay), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Winners entry point', () {
    // This suite's harness can only exercise the zero-winners state (see
    // the `client.from(any())` throw in setUp -- winners are only ever
    // fetched past that point in the cubit's load()). Full winner-card
    // rendering/removal is covered directly in winners_page_test.dart and
    // view_winners_button_test.dart; this guards the wiring on THIS page --
    // no entry point, no stray winner-card content when there are none.
    testWidgets(
      'no winner cards and no "View Winners" entry point render inline when the giveaway '
      'has no winners yet',
      (tester) async {
        await pumpAnalytics(tester);

        expect(find.byType(ViewWinnersButton), findsNothing);
        expect(find.byType(WinnersPage), findsNothing);
        expect(find.textContaining('View Winners'), findsNothing);
        expect(find.text('WINNER'), findsNothing);
      },
    );
  });

  group('Delete Giveaway', () {
    // Pushed from a placeholder root (rather than being the app's only
    // route) so a successful delete's Navigator.pop() has somewhere real to
    // land -- verifying it actually leaves the Analytics page, not just
    // that pop() didn't crash on an empty stack.
    Future<void> pumpAnalyticsWithBackStack(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ar')],
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GiveawayAnalyticsPage(giveawayId: 'g1')),
                  ),
                  child: const Text('Open Analytics'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Analytics'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'tapping the delete icon shows a confirmation dialog explaining the action is '
      'permanent, and does NOT call deleteGiveaway until confirmed',
      (tester) async {
        await pumpAnalyticsWithBackStack(tester);

        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Delete Giveaway?'), findsOneWidget);
        expect(find.textContaining('permanently delete'), findsOneWidget);
        verifyNever(() => giveawayRepository.deleteGiveaway(any()));
      },
    );

    testWidgets('Cancel dismisses the dialog and never calls deleteGiveaway', (tester) async {
      await pumpAnalyticsWithBackStack(tester);

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Giveaway?'), findsNothing);
      verifyNever(() => giveawayRepository.deleteGiveaway(any()));
      // Still on the Analytics page -- nothing was popped.
      expect(find.byType(GiveawayAnalyticsPage), findsOneWidget);
    });

    testWidgets(
      'confirming Delete calls GiveawayRepository.deleteGiveaway with this exact giveaway id, '
      'and on success pops back off the Analytics page',
      (tester) async {
        when(
          () => giveawayRepository.deleteGiveaway('g1'),
        ).thenAnswer((_) async => const Result.success(null));

        await pumpAnalyticsWithBackStack(tester);

        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        verify(() => giveawayRepository.deleteGiveaway('g1')).called(1);
        expect(find.byType(GiveawayAnalyticsPage), findsNothing);
        expect(find.text('Open Analytics'), findsOneWidget);
        expect(find.text('Giveaway deleted.'), findsOneWidget);
      },
    );

    testWidgets(
      'a failed delete shows an error message and stays on the Analytics page -- nothing is '
      'popped, nothing is removed',
      (tester) async {
        when(() => giveawayRepository.deleteGiveaway('g1')).thenAnswer(
          (_) async =>
              const Result.failure(UnauthorizedFailure('You can only delete your own giveaways.')),
        );

        await pumpAnalyticsWithBackStack(tester);

        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        verify(() => giveawayRepository.deleteGiveaway('g1')).called(1);
        expect(find.byType(GiveawayAnalyticsPage), findsOneWidget);
        // UnauthorizedFailure.localize() always shows this fixed copy,
        // regardless of the raw message the repository/server returned --
        // see Failure's own doc comment on message vs. localize().
        expect(find.text('You are not authorized to do that.'), findsOneWidget);
      },
    );
  });
}
