import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/error/failure.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/admin_giveaways/presentation/bloc/admin_giveaways_cubit.dart';
import 'package:rewardsapp/features/admin_giveaways/presentation/bloc/admin_giveaways_state.dart';
import 'package:rewardsapp/shared/models/giveaway.dart';
import 'package:rewardsapp/shared/repositories/giveaway_repository.dart';

class MockGiveawayRepository extends Mock implements GiveawayRepository {}

Giveaway _giveaway(String id) => Giveaway(
  id: id,
  title: 'Title $id',
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
  participantCount: 3,
);

void main() {
  late MockGiveawayRepository repository;

  setUp(() => repository = MockGiveawayRepository());

  group('AdminGiveawaysCubit', () {
    blocTest<AdminGiveawaysCubit, AdminGiveawaysState>(
      'always forces a fresh (non-cached) read -- admin data must be correctness-first',
      build: () => AdminGiveawaysCubit(repository),
      setUp: () => when(
        () => repository.getGiveaways(forceRefresh: true),
      ).thenAnswer((_) async => Result.success([_giveaway('1')])),
      act: (cubit) => cubit.load(),
      expect: () => [
        const AdminGiveawaysState(status: AdminGiveawaysStatus.loading),
        AdminGiveawaysState(status: AdminGiveawaysStatus.loaded, giveaways: [_giveaway('1')]),
      ],
      verify: (_) {
        verify(() => repository.getGiveaways(forceRefresh: true)).called(1);
      },
    );

    blocTest<AdminGiveawaysCubit, AdminGiveawaysState>(
      'emits error on failure',
      build: () => AdminGiveawaysCubit(repository),
      setUp: () => when(
        () => repository.getGiveaways(forceRefresh: true),
      ).thenAnswer((_) async => const Result.failure(NetworkFailure())),
      act: (cubit) => cubit.load(),
      expect: () => [
        const AdminGiveawaysState(status: AdminGiveawaysStatus.loading),
        const AdminGiveawaysState(status: AdminGiveawaysStatus.error, failure: NetworkFailure()),
      ],
    );
  });
}
