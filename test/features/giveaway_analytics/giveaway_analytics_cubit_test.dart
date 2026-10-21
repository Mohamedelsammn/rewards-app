import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/error/failure.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/giveaway_analytics/presentation/bloc/giveaway_analytics_cubit.dart';
import 'package:rewardsapp/features/giveaway_analytics/presentation/bloc/giveaway_analytics_state.dart';
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

final _winner = Winner(
  id: 'w1',
  giveawayId: 'g1',
  participationId: 'p1',
  rank: 1,
  selectedAt: DateTime(2026, 1, 1),
  celebrationAcknowledgedAt: null,
  participationNumber: 4821,
);

final _giveawayWithImage = Giveaway(
  id: 'g1',
  title: 'Win a Car',
  organizerName: 'Acme Co',
  prizeDescription: 'A car',
  descriptionRules: 'Rules',
  imageUrl: 'https://example.supabase.co/storage/v1/object/public/giveaway-images/abc123.jpg',
  startDate: DateTime(2026, 1, 1),
  endDate: DateTime(2026, 1, 10),
  endTime: '18:00',
  status: GiveawayStatus.active,
  numberDigitWidth: 4,
  maxParticipants: null,
  participantCount: 5,
);

final _alice = EligibleParticipant(
  participationId: 'p-alice',
  participationNumber: 1111,
  fullName: 'Alice QA',
  createdAt: DateTime(2026, 1, 1),
  phoneE164: '+12025550101',
);

void main() {
  late MockGiveawayRepository giveawayRepository;
  late MockWinnerRepository winnerRepository;
  late MockSupabaseClient client;
  late MockStorageRepository storageRepository;

  setUp(() {
    giveawayRepository = MockGiveawayRepository();
    winnerRepository = MockWinnerRepository();
    client = MockSupabaseClient();
    storageRepository = MockStorageRepository();
    when(() => storageRepository.deleteGiveawayImage(any())).thenAnswer((_) async {});
  });

  GiveawayAnalyticsCubit buildCubit() =>
      GiveawayAnalyticsCubit(giveawayRepository, winnerRepository, client, storageRepository);

  group('GiveawayAnalyticsCubit.selectWinner', () {
    // Covers the admin-isolation fix in fn_select_winner /
    // WinnerRepository._mapError: an admin can never select a winner for a
    // giveaway they don't own, even by calling the Edge Function directly.
    blocTest<GiveawayAnalyticsCubit, GiveawayAnalyticsState>(
      'surfaces UnauthorizedFailure and does not reload when the admin does not own the giveaway',
      build: buildCubit,
      setUp: () {
        when(
          () => winnerRepository.selectWinner(giveawayId: 'g1', participationId: null, rank: 1),
        ).thenAnswer(
          (_) async => const Result.failure(
            UnauthorizedFailure('You can only select winners for your own giveaways.'),
          ),
        );
      },
      act: (cubit) => cubit.selectWinner('g1'),
      expect: () => [
        const GiveawayAnalyticsState(isSelectingWinner: true),
        const GiveawayAnalyticsState(isSelectingWinner: false),
        const GiveawayAnalyticsState(
          isSelectingWinner: false,
          failure: UnauthorizedFailure('You can only select winners for your own giveaways.'),
        ),
      ],
      verify: (_) {
        verifyNever(
          () => giveawayRepository.getGiveawayById(any(), forceRefresh: any(named: 'forceRefresh')),
        );
      },
    );

    blocTest<GiveawayAnalyticsCubit, GiveawayAnalyticsState>(
      'on success, captures the full winner in lastSelectedWinner (available immediately, '
      'without waiting on the fire-and-forget reload) and reloads the giveaway',
      build: buildCubit,
      setUp: () {
        when(
          () => winnerRepository.selectWinner(giveawayId: 'g1', participationId: null, rank: 1),
        ).thenAnswer((_) async => Result.success(_winner));
        when(
          () => giveawayRepository.getGiveawayById('g1', forceRefresh: true),
        ).thenAnswer((_) async => const Result.failure(NetworkFailure()));
      },
      act: (cubit) => cubit.selectWinner('g1'),
      expect: () => [
        const GiveawayAnalyticsState(isSelectingWinner: true),
        const GiveawayAnalyticsState(isSelectingWinner: false),
        GiveawayAnalyticsState(isSelectingWinner: false, lastSelectedWinner: _winner),
        // load()'s own leading `status: loading` emit is a no-op here: it's
        // identical to the state already in place (Cubit skips re-emitting
        // an equal consecutive state), so only the final error state shows.
        GiveawayAnalyticsState(
          status: GiveawayAnalyticsStatus.error,
          failure: const NetworkFailure(),
          lastSelectedWinner: _winner,
        ),
      ],
      verify: (_) {
        verify(() => giveawayRepository.getGiveawayById('g1', forceRefresh: true)).called(1);
      },
    );

    blocTest<GiveawayAnalyticsCubit, GiveawayAnalyticsState>(
      'a pending manual target is consumed (cleared) the instant selectWinner resolves, '
      'whether or not it was actually used',
      build: buildCubit,
      seed: () => GiveawayAnalyticsState(manualTarget: _alice),
      setUp: () {
        when(
          () =>
              winnerRepository.selectWinner(giveawayId: 'g1', participationId: 'p-alice', rank: 1),
        ).thenAnswer((_) async => Result.success(_winner));
        when(
          () => giveawayRepository.getGiveawayById('g1', forceRefresh: true),
        ).thenAnswer((_) async => const Result.failure(NetworkFailure()));
      },
      act: (cubit) => cubit.selectWinner('g1', participationId: 'p-alice'),
      verify: (cubit) {
        expect(cubit.state.manualTarget, isNull);
      },
    );

    blocTest<GiveawayAnalyticsCubit, GiveawayAnalyticsState>(
      'a pending manual target survives a failed selection attempt -- the admin should not '
      'have to re-pick after e.g. a transient network error',
      build: buildCubit,
      seed: () => GiveawayAnalyticsState(manualTarget: _alice),
      setUp: () {
        when(
          () =>
              winnerRepository.selectWinner(giveawayId: 'g1', participationId: 'p-alice', rank: 1),
        ).thenAnswer((_) async => const Result.failure(NetworkFailure()));
      },
      act: (cubit) => cubit.selectWinner('g1', participationId: 'p-alice'),
      verify: (cubit) {
        expect(cubit.state.manualTarget, _alice);
      },
    );

    // Multi-winner support: a second (third, fourth, ...) call must never
    // re-send rank 1 -- that would violate the winners(giveaway_id,
    // participation_id) uniqueness path for a *different* participant while
    // silently colliding with the first winner's rank in the UI. The next
    // rank is always derived from how many winners are already loaded.
    blocTest<GiveawayAnalyticsCubit, GiveawayAnalyticsState>(
      'requests the next rank (existing winners + 1) when selecting another winner',
      build: buildCubit,
      seed: () =>
          GiveawayAnalyticsState(status: GiveawayAnalyticsStatus.loaded, winners: [_winner]),
      setUp: () {
        when(
          () => winnerRepository.selectWinner(giveawayId: 'g1', participationId: null, rank: 2),
        ).thenAnswer(
          (_) async => Result.success(
            Winner(
              id: 'w2',
              giveawayId: 'g1',
              participationId: 'p2',
              rank: 2,
              selectedAt: DateTime(2026, 1, 2),
              celebrationAcknowledgedAt: null,
              participationNumber: 1173,
            ),
          ),
        );
        when(
          () => giveawayRepository.getGiveawayById('g1', forceRefresh: true),
        ).thenAnswer((_) async => const Result.failure(NetworkFailure()));
      },
      act: (cubit) => cubit.selectWinner('g1'),
      verify: (_) {
        verify(
          () => winnerRepository.selectWinner(giveawayId: 'g1', participationId: null, rank: 2),
        ).called(1);
      },
    );

    test('returns true only once the server confirms the winner was persisted', () async {
      final cubit = GiveawayAnalyticsCubit(
        giveawayRepository,
        winnerRepository,
        client,
        storageRepository,
      );
      when(
        () => winnerRepository.selectWinner(giveawayId: 'g1', participationId: null, rank: 1),
      ).thenAnswer((_) async => Result.success(_winner));
      when(
        () => giveawayRepository.getGiveawayById('g1', forceRefresh: true),
      ).thenAnswer((_) async => const Result.failure(NetworkFailure()));

      expect(await cubit.selectWinner('g1'), isTrue);
      // selectWinner() fires load() without awaiting it (a deliberate
      // fire-and-forget refresh) -- let that pending work settle before
      // closing the cubit, or its trailing emit races the close.
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
    });

    test('returns false and never signals success when the server rejects the selection', () async {
      final cubit = GiveawayAnalyticsCubit(
        giveawayRepository,
        winnerRepository,
        client,
        storageRepository,
      );
      when(
        () => winnerRepository.selectWinner(giveawayId: 'g1', participationId: null, rank: 1),
      ).thenAnswer(
        (_) async => const Result.failure(ValidationFailure('no_eligible_participants')),
      );

      expect(await cubit.selectWinner('g1'), isFalse);
      await cubit.close();
    });
  });

  group('GiveawayAnalyticsCubit.deleteGiveaway', () {
    blocTest<GiveawayAnalyticsCubit, GiveawayAnalyticsState>(
      'on success, calls GiveawayRepository.deleteGiveaway with the exact giveaway id and '
      'best-effort forwards the CURRENT giveaway image to Storage cleanup -- never touches '
      'WinnerRepository / winner-selection logic',
      build: buildCubit,
      seed: () => GiveawayAnalyticsState(
        status: GiveawayAnalyticsStatus.loaded,
        giveaway: _giveawayWithImage,
      ),
      setUp: () {
        when(
          () => giveawayRepository.deleteGiveaway('g1'),
        ).thenAnswer((_) async => const Result.success(null));
      },
      act: (cubit) => cubit.deleteGiveaway('g1'),
      verify: (_) {
        verify(() => giveawayRepository.deleteGiveaway('g1')).called(1);
        verify(() => storageRepository.deleteGiveawayImage(_giveawayWithImage.imageUrl)).called(1);
        verifyNever(
          () => winnerRepository.selectWinner(
            giveawayId: any(named: 'giveawayId'),
            participationId: any(named: 'participationId'),
            rank: any(named: 'rank'),
          ),
        );
      },
    );

    test('returns true only once the server confirms the delete', () async {
      final cubit = buildCubit();
      when(
        () => giveawayRepository.deleteGiveaway('g1'),
      ).thenAnswer((_) async => const Result.success(null));

      expect(await cubit.deleteGiveaway('g1'), isTrue);
      await cubit.close();
    });

    blocTest<GiveawayAnalyticsCubit, GiveawayAnalyticsState>(
      'returns false and surfaces the failure when the server rejects the delete (e.g. the '
      'admin does not own this giveaway) -- no local removal, no Storage cleanup attempted',
      build: buildCubit,
      setUp: () {
        when(() => giveawayRepository.deleteGiveaway('g1')).thenAnswer(
          (_) async =>
              const Result.failure(UnauthorizedFailure('You can only delete your own giveaways.')),
        );
      },
      act: (cubit) => cubit.deleteGiveaway('g1'),
      expect: () => [
        const GiveawayAnalyticsState(
          failure: UnauthorizedFailure('You can only delete your own giveaways.'),
        ),
      ],
      verify: (_) {
        verifyNever(() => storageRepository.deleteGiveawayImage(any()));
      },
    );
  });

  group('GiveawayAnalyticsCubit manual target', () {
    blocTest<GiveawayAnalyticsCubit, GiveawayAnalyticsState>(
      'setManualTarget stores the chosen participant as pending -- nothing is selected yet',
      build: buildCubit,
      act: (cubit) => cubit.setManualTarget(_alice),
      expect: () => [GiveawayAnalyticsState(manualTarget: _alice)],
      verify: (_) {
        verifyNever(
          () => winnerRepository.selectWinner(
            giveawayId: any(named: 'giveawayId'),
            participationId: any(named: 'participationId'),
            rank: any(named: 'rank'),
          ),
        );
      },
    );

    blocTest<GiveawayAnalyticsCubit, GiveawayAnalyticsState>(
      'choosing a different participant overwrites the previous pending target',
      build: buildCubit,
      seed: () => GiveawayAnalyticsState(manualTarget: _alice),
      act: (cubit) => cubit.setManualTarget(
        EligibleParticipant(
          participationId: 'p-bob',
          participationNumber: 2222,
          fullName: 'Bob QA',
          createdAt: DateTime(2026, 1, 1),
        ),
      ),
      verify: (cubit) {
        expect(cubit.state.manualTarget?.participationId, 'p-bob');
      },
    );

    blocTest<GiveawayAnalyticsCubit, GiveawayAnalyticsState>(
      'clearManualTarget reverts to the normal random behavior',
      build: buildCubit,
      seed: () => GiveawayAnalyticsState(manualTarget: _alice),
      act: (cubit) => cubit.clearManualTarget(),
      expect: () => [const GiveawayAnalyticsState()],
    );

    blocTest<GiveawayAnalyticsCubit, GiveawayAnalyticsState>(
      'an unrelated state update (e.g. a realtime-triggered load) does not clear the pending '
      'manual target',
      build: buildCubit,
      seed: () => GiveawayAnalyticsState(manualTarget: _alice),
      setUp: () {
        when(
          () => giveawayRepository.getGiveawayById('g1', forceRefresh: true),
        ).thenAnswer((_) async => const Result.failure(NetworkFailure()));
      },
      act: (cubit) => cubit.load('g1'),
      verify: (cubit) {
        expect(cubit.state.manualTarget, _alice);
      },
    );
  });
}
