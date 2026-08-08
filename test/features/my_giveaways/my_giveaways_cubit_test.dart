import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/error/failure.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/my_giveaways/presentation/bloc/my_giveaways_cubit.dart';
import 'package:rewardsapp/features/my_giveaways/presentation/bloc/my_giveaways_state.dart';
import 'package:rewardsapp/shared/models/participation.dart';
import 'package:rewardsapp/shared/repositories/participation_repository.dart';

class MockParticipationRepository extends Mock implements ParticipationRepository {}

void main() {
  late MockParticipationRepository repository;

  setUp(() => repository = MockParticipationRepository());

  final participation = Participation(
    id: 'p1',
    giveawayId: 'g1',
    participationSequence: 1,
    participationNumber: 42,
    scratchRevealedAt: null,
    createdAt: DateTime(2026, 1, 1),
  );

  group('MyGiveawaysCubit', () {
    blocTest<MyGiveawaysCubit, MyGiveawaysState>(
      'emits empty when there are no participations',
      build: () => MyGiveawaysCubit(repository),
      setUp: () => when(
        () => repository.getMyParticipations(forceRefresh: false),
      ).thenAnswer((_) async => const Result.success([])),
      act: (cubit) => cubit.load(),
      expect: () => [
        const MyGiveawaysState(status: MyGiveawaysStatus.loading),
        const MyGiveawaysState(status: MyGiveawaysStatus.empty, participations: []),
      ],
    );

    blocTest<MyGiveawaysCubit, MyGiveawaysState>(
      'emits loaded with participations on success',
      build: () => MyGiveawaysCubit(repository),
      setUp: () => when(
        () => repository.getMyParticipations(forceRefresh: false),
      ).thenAnswer((_) async => Result.success([participation])),
      act: (cubit) => cubit.load(),
      expect: () => [
        const MyGiveawaysState(status: MyGiveawaysStatus.loading),
        MyGiveawaysState(status: MyGiveawaysStatus.loaded, participations: [participation]),
      ],
    );

    blocTest<MyGiveawaysCubit, MyGiveawaysState>(
      'emits error on failure',
      build: () => MyGiveawaysCubit(repository),
      setUp: () => when(
        () => repository.getMyParticipations(forceRefresh: false),
      ).thenAnswer((_) async => const Result.failure(NetworkFailure())),
      act: (cubit) => cubit.load(),
      expect: () => [
        const MyGiveawaysState(status: MyGiveawaysStatus.loading),
        const MyGiveawaysState(status: MyGiveawaysStatus.error, failure: NetworkFailure()),
      ],
    );
  });
}
