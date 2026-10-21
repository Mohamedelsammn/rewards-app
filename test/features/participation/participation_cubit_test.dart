import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/error/failure.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/participation/presentation/bloc/participation_cubit.dart';
import 'package:rewardsapp/features/participation/presentation/bloc/participation_state.dart';
import 'package:rewardsapp/services/secure_storage_service.dart';
import 'package:rewardsapp/shared/models/giveaway.dart';
import 'package:rewardsapp/shared/models/participation.dart';
import 'package:rewardsapp/shared/repositories/giveaway_repository.dart';
import 'package:rewardsapp/shared/repositories/participation_repository.dart';
import 'package:rewardsapp/shared/repositories/user_repository.dart';

class _Storage extends Mock implements SecureStorageService {}

class _Users extends Mock implements UserRepository {}

class _Participations extends Mock implements ParticipationRepository {}

class _Giveaways extends Mock implements GiveawayRepository {}

void main() {
  late _Storage storage;
  late _Users users;
  late _Participations participations;
  late _Giveaways giveaways;

  final participation = Participation(
    id: 'p1',
    giveawayId: 'g1',
    participationSequence: 1,
    participationNumber: 4821,
    scratchRevealedAt: null,
    createdAt: DateTime(2026),
  );

  ParticipationCubit build({Future<bool> Function()? watch}) => ParticipationCubit(
    giveawayId: 'g1',
    secureStorage: storage,
    userRepository: users,
    participationRepository: participations,
    giveawayRepository: giveaways,
    showRewardedAd: watch ?? () async => false,
  );

  setUp(() {
    storage = _Storage();
    users = _Users();
    participations = _Participations();
    giveaways = _Giveaways();
    when(() => storage.cachedUserId).thenAnswer((_) async => 'profile-1');
    when(
      () => participations.getMyParticipationForGiveaway('g1'),
    ).thenAnswer((_) async => const Result.success(null));
    when(() => giveaways.getGiveawayById('g1', forceRefresh: true)).thenAnswer(
      (_) async => Result.success(
        Giveaway(
          id: 'g1',
          title: 'G',
          organizerName: 'O',
          prizeDescription: '',
          descriptionRules: '',
          imageUrl: null,
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 1)),
          endTime: '23:59',
          status: GiveawayStatus.active,
          numberDigitWidth: 4,
          maxParticipants: null,
          participantCount: 0,
        ),
      ),
    );
    when(() => giveaways.invalidateAfterParticipation('g1')).thenAnswer((_) async {});
    when(() => participations.markRewardFrameEarned('g1')).thenAnswer((_) async {});
    when(
      () => participations.attachRewardFrameToParticipation(
        giveawayId: any(named: 'giveawayId'),
        participationId: any(named: 'participationId'),
      ),
    ).thenAnswer((_) async {});
    when(() => participations.hasPendingRewardFrame('g1')).thenReturn(false);
    when(
      () => participations.hasRewardFrameEntitlement(
        giveawayId: any(named: 'giveawayId'),
        participationId: any(named: 'participationId'),
      ),
    ).thenReturn(false);
  });

  test('existing participant resolves directly without preparing or showing an ad', () async {
    when(
      () => participations.getMyParticipationForGiveaway('g1'),
    ).thenAnswer((_) async => Result.success(participation));
    final cubit = build(watch: () async => fail('not called'));
    await cubit.start();
    expect(cubit.state.step, ParticipationStep.alreadyParticipating);
    expect(cubit.state.participationNumber, 4821);
    verifyNever(() => participations.markRewardFrameEarned(any()));
    verifyNever(() => participations.createParticipation(giveawayId: any(named: 'giveawayId')));
    await cubit.close();
  });

  test('closing the choice joins freely without showing or recording a rewarded ad', () async {
    when(
      () => participations.createParticipation(giveawayId: 'g1'),
    ).thenAnswer((_) async => Result.success(participation));
    final cubit = build();
    await cubit.start();
    expect(cubit.state.step, ParticipationStep.readyToJoin);
    await cubit.joinWithoutAd();
    expect(cubit.state.step, ParticipationStep.success);
    expect(cubit.state.participationNumber, 4821);
    expect(cubit.state.rewardedFrameUnlocked, isFalse);
    verifyNever(() => participations.markRewardFrameEarned(any()));
    verify(() => participations.createParticipation(giveawayId: 'g1')).called(1);
    await cubit.close();
  });

  test(
    'client reward callback success persists cosmetic entitlement and creates one entry',
    () async {
      when(
        () => participations.createParticipation(giveawayId: 'g1'),
      ).thenAnswer((_) async => Result.success(participation));
      var adCalls = 0;
      final cubit = build(
        watch: () async {
          adCalls++;
          return true;
        },
      );
      await cubit.start();
      await cubit.joinWithRewardedAd();
      expect(adCalls, 1);
      expect(cubit.state.step, ParticipationStep.success);
      expect(cubit.state.participationNumber, 4821);
      expect(cubit.state.rewardedFrameUnlocked, isTrue);
      verify(() => participations.createParticipation(giveawayId: 'g1')).called(1);
      verify(() => participations.markRewardFrameEarned('g1')).called(1);
      verify(
        () => participations.attachRewardFrameToParticipation(
          giveawayId: 'g1',
          participationId: 'p1',
        ),
      ).called(1);
      await cubit.close();
    },
  );

  test('unavailable or failed rewarded ad falls through to free participation', () async {
    when(
      () => participations.createParticipation(giveawayId: 'g1'),
    ).thenAnswer((_) async => Result.success(participation));
    final cubit = build(watch: () async => false);
    await cubit.start();
    await cubit.joinWithRewardedAd();
    expect(cubit.state.step, ParticipationStep.success);
    verifyNever(() => participations.markRewardFrameEarned(any()));
    verifyNever(
      () => participations.attachRewardFrameToParticipation(
        giveawayId: any(named: 'giveawayId'),
        participationId: any(named: 'participationId'),
      ),
    );
    verify(() => participations.createParticipation(giveawayId: 'g1')).called(1);
    await cubit.close();
  });

  test('repeated taps cannot issue duplicate participation requests', () async {
    final gate = Completer<Result<Participation>>();
    when(() => participations.createParticipation(giveawayId: 'g1')).thenAnswer((_) => gate.future);
    final cubit = build();
    await cubit.start();
    final first = cubit.joinWithoutAd();
    final duplicate = cubit.joinWithoutAd();
    gate.complete(Result.success(participation));
    await Future.wait([first, duplicate]);
    verify(() => participations.createParticipation(giveawayId: 'g1')).called(1);
    await cubit.close();
  });

  test('participation backend failures remain retryable and do not invent a number', () async {
    when(
      () => participations.createParticipation(giveawayId: 'g1'),
    ).thenAnswer((_) async => const Result.failure(NetworkFailure()));
    final cubit = build();
    await cubit.start();
    await cubit.joinWithoutAd();
    expect(cubit.state.step, ParticipationStep.failure);
    expect(cubit.state.participationNumber, isNull);
    await cubit.close();
  });

  test('earned local frame survives a backend failure and is attached after retry', () async {
    var attempts = 0;
    when(() => participations.createParticipation(giveawayId: 'g1')).thenAnswer((_) async {
      attempts++;
      return attempts == 1 ? const Result.failure(NetworkFailure()) : Result.success(participation);
    });
    final cubit = build(watch: () async => true);
    await cubit.start();
    await cubit.joinWithRewardedAd();
    expect(cubit.state.step, ParticipationStep.failure);
    await cubit.retry();
    expect(cubit.state.step, ParticipationStep.success);
    verify(() => participations.markRewardFrameEarned('g1')).called(1);
    verify(
      () =>
          participations.attachRewardFrameToParticipation(giveawayId: 'g1', participationId: 'p1'),
    ).called(1);
    await cubit.close();
  });

  test('a persisted pending reward resumes join without a second ad prompt', () async {
    when(() => participations.hasPendingRewardFrame('g1')).thenReturn(true);
    when(
      () => participations.createParticipation(giveawayId: 'g1'),
    ).thenAnswer((_) async => Result.success(participation));
    var adCalls = 0;
    final cubit = build(
      watch: () async {
        adCalls++;
        return true;
      },
    );

    await cubit.start();

    expect(adCalls, 0);
    expect(cubit.state.step, ParticipationStep.success);
    expect(cubit.state.rewardedFrameUnlocked, isTrue);
    verify(() => participations.createParticipation(giveawayId: 'g1')).called(1);
    await cubit.close();
  });
}
