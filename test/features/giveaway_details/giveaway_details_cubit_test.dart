import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/error/failure.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/giveaway_details/presentation/bloc/giveaway_details_cubit.dart';
import 'package:rewardsapp/features/giveaway_details/presentation/bloc/giveaway_details_state.dart';
import 'package:rewardsapp/shared/models/giveaway.dart';
import 'package:rewardsapp/shared/models/participation.dart';
import 'package:rewardsapp/shared/repositories/giveaway_repository.dart';
import 'package:rewardsapp/shared/repositories/participation_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGiveawayRepository extends Mock implements GiveawayRepository {}

class MockParticipationRepository extends Mock implements ParticipationRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

final _giveaway = Giveaway(
  id: 'g1',
  title: 'Tesla Model S Plaid',
  organizerName: 'Lumina Rewards',
  prizeDescription: 'A car',
  descriptionRules: 'Rules',
  imageUrl: null,
  startDate: DateTime(2026, 1, 1),
  endDate: DateTime(2026, 1, 10),
  endTime: '18:00',
  status: GiveawayStatus.active,
  numberDigitWidth: 4,
  maxParticipants: null,
  participantCount: 5,
);

void main() {
  late MockGiveawayRepository giveawayRepository;
  late MockParticipationRepository participationRepository;
  late MockSupabaseClient client;

  setUp(() {
    giveawayRepository = MockGiveawayRepository();
    participationRepository = MockParticipationRepository();
    client = MockSupabaseClient();
    when(
      () => giveawayRepository.getGiveawayById('g1', forceRefresh: false),
    ).thenAnswer((_) async => Result.success(_giveaway));
    when(
      () => giveawayRepository.getRequirements('g1'),
    ).thenAnswer((_) async => const Result.success([]));
    // Cold cache by default -- individual tests override this to prove the
    // warm-cache/seed fast paths.
    when(() => giveawayRepository.peekCachedGiveaway(any())).thenReturn(null);
  });

  group('GiveawayDetailsCubit', () {
    blocTest<GiveawayDetailsCubit, GiveawayDetailsState>(
      'a cold cache (no peek hit, no seed) loads giveaway and reflects not-yet-joined',
      build: () => GiveawayDetailsCubit(giveawayRepository, participationRepository, client),
      setUp: () {
        when(
          () => participationRepository.getMyParticipationForGiveaway('g1'),
        ).thenAnswer((_) async => const Result.success(null));
      },
      act: (cubit) => cubit.load('g1'),
      expect: () => [
        const GiveawayDetailsState(status: GiveawayDetailsStatus.loading),
        GiveawayDetailsState(
          status: GiveawayDetailsStatus.loaded,
          giveaway: _giveaway,
          requirements: const [],
          alreadyJoined: false,
          participationCheckStatus: ParticipationCheckStatus.notJoined,
        ),
      ],
    );

    blocTest<GiveawayDetailsCubit, GiveawayDetailsState>(
      'reflects already-joined with the persisted participation number',
      build: () => GiveawayDetailsCubit(giveawayRepository, participationRepository, client),
      setUp: () {
        when(() => participationRepository.getMyParticipationForGiveaway('g1')).thenAnswer(
          (_) async => Result.success(
            Participation(
              id: 'p1',
              giveawayId: 'g1',
              participationSequence: 1,
              participationNumber: 4821,
              scratchRevealedAt: null,
              createdAt: DateTime(2026, 1, 2),
            ),
          ),
        );
      },
      act: (cubit) => cubit.load('g1'),
      expect: () => [
        const GiveawayDetailsState(status: GiveawayDetailsStatus.loading),
        GiveawayDetailsState(
          status: GiveawayDetailsStatus.loaded,
          giveaway: _giveaway,
          requirements: const [],
          alreadyJoined: true,
          participationCheckStatus: ParticipationCheckStatus.joined,
          myParticipationNumber: 4821,
        ),
      ],
    );

    blocTest<GiveawayDetailsCubit, GiveawayDetailsState>(
      'emits error when the giveaway fails to load',
      build: () => GiveawayDetailsCubit(giveawayRepository, participationRepository, client),
      setUp: () {
        when(
          () => giveawayRepository.getGiveawayById('missing', forceRefresh: false),
        ).thenAnswer((_) async => const Result.failure(GiveawayEndedFailure()));
      },
      act: (cubit) => cubit.load('missing'),
      expect: () => [
        const GiveawayDetailsState(status: GiveawayDetailsStatus.loading),
        const GiveawayDetailsState(
          status: GiveawayDetailsStatus.error,
          failure: GiveawayEndedFailure(),
        ),
      ],
    );

    blocTest<GiveawayDetailsCubit, GiveawayDetailsState>(
      'a seed passed in by the caller (e.g. tapping a card that already has this '
      'giveaway in memory) renders instantly -- load() never emits a loading state',
      build: () => GiveawayDetailsCubit(
        giveawayRepository,
        participationRepository,
        client,
        seed: _giveaway,
      ),
      setUp: () {
        when(
          () => participationRepository.getMyParticipationForGiveaway('g1'),
        ).thenAnswer((_) async => const Result.success(null));
      },
      act: (cubit) => cubit.load('g1'),
      expect: () => [
        // Only the final "refreshed with full requirements/participation
        // data" emission -- the constructor already seeded status: loaded,
        // so load() never has to show a spinner.
        GiveawayDetailsState(
          status: GiveawayDetailsStatus.loaded,
          giveaway: _giveaway,
          requirements: const [],
          alreadyJoined: false,
          participationCheckStatus: ParticipationCheckStatus.notJoined,
        ),
      ],
    );

    blocTest<GiveawayDetailsCubit, GiveawayDetailsState>(
      'a warm cache peek (no seed) also renders instantly without a loading state',
      build: () => GiveawayDetailsCubit(giveawayRepository, participationRepository, client),
      setUp: () {
        when(() => giveawayRepository.peekCachedGiveaway('g1')).thenReturn(_giveaway);
        when(
          () => participationRepository.getMyParticipationForGiveaway('g1'),
        ).thenAnswer((_) async => const Result.success(null));
      },
      act: (cubit) => cubit.load('g1'),
      expect: () => [
        // Cache data can render immediately, while the CTA remains in its
        // participation-check loading state until the identity lookup ends.
        GiveawayDetailsState(status: GiveawayDetailsStatus.loaded, giveaway: _giveaway),
        GiveawayDetailsState(
          status: GiveawayDetailsStatus.loaded,
          giveaway: _giveaway,
          requirements: const [],
          participationCheckStatus: ParticipationCheckStatus.notJoined,
        ),
      ],
    );

    blocTest<GiveawayDetailsCubit, GiveawayDetailsState>(
      'a failed participation check remains unknown and never becomes not-joined',
      build: () => GiveawayDetailsCubit(giveawayRepository, participationRepository, client),
      setUp: () {
        when(
          () => participationRepository.getMyParticipationForGiveaway('g1'),
        ).thenAnswer((_) async => const Result.failure(UnauthorizedFailure()));
      },
      act: (cubit) => cubit.load('g1'),
      expect: () => [
        const GiveawayDetailsState(status: GiveawayDetailsStatus.loading),
        GiveawayDetailsState(
          status: GiveawayDetailsStatus.loaded,
          giveaway: _giveaway,
          requirements: const [],
          participationCheckStatus: ParticipationCheckStatus.error,
        ),
      ],
    );
  });
}
