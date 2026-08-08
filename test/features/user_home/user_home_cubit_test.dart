import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/error/failure.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/user_home/presentation/bloc/user_home_cubit.dart';
import 'package:rewardsapp/features/user_home/presentation/bloc/user_home_state.dart';
import 'package:rewardsapp/shared/models/giveaway.dart';
import 'package:rewardsapp/shared/repositories/giveaway_repository.dart';

class MockGiveawayRepository extends Mock implements GiveawayRepository {}

Giveaway _giveaway(String id, String title) => Giveaway(
  id: id,
  title: title,
  organizerName: 'Org',
  prizeDescription: 'Prize',
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
  late MockGiveawayRepository repository;

  setUp(() {
    repository = MockGiveawayRepository();
  });

  group('UserHomeCubit', () {
    blocTest<UserHomeCubit, UserHomeState>(
      'emits loading then loaded on successful fetch',
      build: () => UserHomeCubit(repository),
      setUp: () {
        when(() => repository.getGiveaways(forceRefresh: false)).thenAnswer(
          (_) async => Result.success([_giveaway('1', 'iPhone'), _giveaway('2', 'Tesla')]),
        );
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const UserHomeState(status: UserHomeStatus.loading),
        UserHomeState(
          status: UserHomeStatus.loaded,
          allGiveaways: [_giveaway('1', 'iPhone'), _giveaway('2', 'Tesla')],
        ),
      ],
    );

    blocTest<UserHomeCubit, UserHomeState>(
      'emits loading then error on failure',
      build: () => UserHomeCubit(repository),
      setUp: () {
        when(
          () => repository.getGiveaways(forceRefresh: false),
        ).thenAnswer((_) async => const Result.failure(NetworkFailure()));
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const UserHomeState(status: UserHomeStatus.loading),
        const UserHomeState(status: UserHomeStatus.error, failure: NetworkFailure()),
      ],
    );

    test('filteredGiveaways narrows by case-insensitive title match', () {
      const state = UserHomeState();
      final populated = state.copyWith(
        allGiveaways: [_giveaway('1', 'iPhone 17 Pro'), _giveaway('2', 'Tesla Model S')],
        searchQuery: 'tesla',
      );
      expect(populated.filteredGiveaways, [_giveaway('2', 'Tesla Model S')]);
    });

    test('featured is the first giveaway and popular excludes it', () {
      const state = UserHomeState();
      final populated = state.copyWith(
        allGiveaways: [_giveaway('1', 'A'), _giveaway('2', 'B'), _giveaway('3', 'C')],
      );
      expect(populated.featured, _giveaway('1', 'A'));
      expect(populated.popular, [_giveaway('2', 'B'), _giveaway('3', 'C')]);
    });
  });
}
