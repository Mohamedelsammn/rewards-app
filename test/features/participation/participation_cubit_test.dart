import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/error/failure.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/participation/presentation/bloc/participation_cubit.dart';
import 'package:rewardsapp/features/participation/presentation/bloc/participation_state.dart';
import 'package:rewardsapp/services/secure_storage_service.dart';
import 'package:rewardsapp/shared/models/participation.dart';
import 'package:rewardsapp/shared/models/user_profile.dart';
import 'package:rewardsapp/shared/repositories/giveaway_repository.dart';
import 'package:rewardsapp/shared/repositories/participation_repository.dart';
import 'package:rewardsapp/shared/repositories/user_repository.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockUserRepository extends Mock implements UserRepository {}

class MockParticipationRepository extends Mock implements ParticipationRepository {}

class MockGiveawayRepository extends Mock implements GiveawayRepository {}

/// V1 has no advertisement system -- participation is a single direct
/// server call once identity is confirmed, with no ad-gating stage.
void main() {
  late MockSecureStorageService secureStorage;
  late MockUserRepository userRepository;
  late MockParticipationRepository participationRepository;
  late MockGiveawayRepository giveawayRepository;

  ParticipationCubit buildCubit() => ParticipationCubit(
    giveawayId: 'g1',
    secureStorage: secureStorage,
    userRepository: userRepository,
    participationRepository: participationRepository,
    giveawayRepository: giveawayRepository,
  );

  setUp(() {
    secureStorage = MockSecureStorageService();
    userRepository = MockUserRepository();
    participationRepository = MockParticipationRepository();
    giveawayRepository = MockGiveawayRepository();

    when(() => giveawayRepository.invalidateAfterParticipation('g1')).thenAnswer((_) async {});
  });

  final participation = Participation(
    id: 'p1',
    giveawayId: 'g1',
    participationSequence: 1,
    participationNumber: 4821,
    scratchRevealedAt: null,
    createdAt: DateTime(2026, 1, 1),
  );

  group('ParticipationCubit', () {
    blocTest<ParticipationCubit, ParticipationState>(
      'start() with no cached identity asks for registration',
      build: buildCubit,
      setUp: () => when(() => secureStorage.cachedUserId).thenAnswer((_) async => null),
      act: (cubit) => cubit.start(),
      expect: () => [
        const ParticipationState(step: ParticipationStep.checkingIdentity),
        const ParticipationState(step: ParticipationStep.needsRegistration),
      ],
    );

    blocTest<ParticipationCubit, ParticipationState>(
      'start() with a cached identity creates the participation directly (no ad step)',
      build: buildCubit,
      setUp: () {
        when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-1');
        when(
          () => participationRepository.createParticipation(giveawayId: 'g1'),
        ).thenAnswer((_) async => Result.success(participation));
      },
      act: (cubit) => cubit.start(),
      expect: () => [
        const ParticipationState(step: ParticipationStep.checkingIdentity),
        const ParticipationState(step: ParticipationStep.creatingParticipation),
        ParticipationState(
          step: ParticipationStep.success,
          participationId: 'p1',
          participationNumber: 4821,
        ),
      ],
      verify: (_) {
        verify(() => giveawayRepository.invalidateAfterParticipation('g1')).called(1);
      },
    );

    blocTest<ParticipationCubit, ParticipationState>(
      'submitRegistration failure surfaces the mapped Failure',
      build: buildCubit,
      setUp: () {
        when(
          () => userRepository.registerOrLink(
            fullName: any(named: 'fullName'),
            phone: any(named: 'phone'),
            countryCode: any(named: 'countryCode'),
          ),
        ).thenAnswer((_) async => const Result.failure(DuplicatePhoneFailure()));
      },
      act: (cubit) =>
          cubit.submitRegistration(fullName: 'Jane', phone: '+12025550190', countryCode: 'US'),
      expect: () => [
        const ParticipationState(step: ParticipationStep.submittingRegistration),
        const ParticipationState(step: ParticipationStep.failure, failure: DuplicatePhoneFailure()),
      ],
    );

    blocTest<ParticipationCubit, ParticipationState>(
      'submitRegistration success saves identity and creates the participation',
      build: buildCubit,
      setUp: () {
        when(
          () => userRepository.registerOrLink(
            fullName: any(named: 'fullName'),
            phone: any(named: 'phone'),
            countryCode: any(named: 'countryCode'),
          ),
        ).thenAnswer(
          (_) async => const Result.success(
            UserProfile(
              id: 'user-1',
              fullName: 'Jane',
              phoneE164: '+12025550190',
              countryCode: 'US',
            ),
          ),
        );
        when(
          () => secureStorage.saveIdentity(userId: 'user-1', fullName: 'Jane'),
        ).thenAnswer((_) async {});
        when(
          () => participationRepository.createParticipation(giveawayId: 'g1'),
        ).thenAnswer((_) async => const Result.failure(GiveawayFullFailure()));
      },
      act: (cubit) =>
          cubit.submitRegistration(fullName: 'Jane', phone: '+12025550190', countryCode: 'US'),
      expect: () => [
        const ParticipationState(step: ParticipationStep.submittingRegistration),
        const ParticipationState(step: ParticipationStep.creatingParticipation),
        const ParticipationState(step: ParticipationStep.failure, failure: GiveawayFullFailure()),
      ],
      verify: (_) {
        verify(() => secureStorage.saveIdentity(userId: 'user-1', fullName: 'Jane')).called(1);
      },
    );

    blocTest<ParticipationCubit, ParticipationState>(
      'createParticipation failure (already joined) surfaces DuplicateParticipationFailure',
      build: buildCubit,
      setUp: () {
        when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-1');
        when(
          () => participationRepository.createParticipation(giveawayId: 'g1'),
        ).thenAnswer((_) async => const Result.failure(DuplicateParticipationFailure()));
      },
      act: (cubit) => cubit.start(),
      expect: () => [
        const ParticipationState(step: ParticipationStep.checkingIdentity),
        const ParticipationState(step: ParticipationStep.creatingParticipation),
        const ParticipationState(
          step: ParticipationStep.failure,
          failure: DuplicateParticipationFailure(),
        ),
      ],
    );

    blocTest<ParticipationCubit, ParticipationState>(
      'retry() with a cached identity re-attempts participation creation',
      build: buildCubit,
      seed: () =>
          const ParticipationState(step: ParticipationStep.failure, failure: NetworkFailure()),
      setUp: () {
        when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-1');
        when(
          () => participationRepository.createParticipation(giveawayId: 'g1'),
        ).thenAnswer((_) async => Result.success(participation));
      },
      act: (cubit) => cubit.retry(),
      expect: () => [
        const ParticipationState(step: ParticipationStep.creatingParticipation),
        ParticipationState(
          step: ParticipationStep.success,
          participationId: 'p1',
          participationNumber: 4821,
        ),
      ],
    );
  });
}
