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

class MockGiveawayRepository extends Mock implements GiveawayRepository {}

class MockParticipationRepository extends Mock implements ParticipationRepository {}

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

  setUp(() {
    giveawayRepository = MockGiveawayRepository();
    participationRepository = MockParticipationRepository();
    when(
      () => giveawayRepository.getGiveawayById('g1', forceRefresh: false),
    ).thenAnswer((_) async => Result.success(_giveaway));
    when(
      () => giveawayRepository.getRequirements('g1'),
    ).thenAnswer((_) async => const Result.success([]));
  });

  group('GiveawayDetailsCubit', () {
    blocTest<GiveawayDetailsCubit, GiveawayDetailsState>(
      'loads giveaway and reflects not-yet-joined',
      build: () => GiveawayDetailsCubit(giveawayRepository, participationRepository),
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
        ),
      ],
    );

    blocTest<GiveawayDetailsCubit, GiveawayDetailsState>(
      'reflects already-joined with the persisted participation number',
      build: () => GiveawayDetailsCubit(giveawayRepository, participationRepository),
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
          myParticipationNumber: 4821,
        ),
      ],
    );

    blocTest<GiveawayDetailsCubit, GiveawayDetailsState>(
      'emits error when the giveaway fails to load',
      build: () => GiveawayDetailsCubit(giveawayRepository, participationRepository),
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
  });
}
