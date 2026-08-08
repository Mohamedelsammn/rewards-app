import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/error/failure.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/create_giveaway/presentation/bloc/create_giveaway_cubit.dart';
import 'package:rewardsapp/features/create_giveaway/presentation/bloc/create_giveaway_state.dart';
import 'package:rewardsapp/shared/models/giveaway.dart';
import 'package:rewardsapp/shared/repositories/giveaway_repository.dart';
import 'package:rewardsapp/shared/repositories/storage_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGiveawayRepository extends Mock implements GiveawayRepository {}

class MockStorageRepository extends Mock implements StorageRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

const _adminUser = User(
  id: 'admin-1',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

final _giveaway = Giveaway(
  id: 'g1',
  title: 'iPhone',
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
  participantCount: 0,
);

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  late MockGiveawayRepository giveawayRepository;
  late MockStorageRepository storageRepository;
  late MockSupabaseClient client;
  late MockGoTrueClient auth;

  setUp(() {
    giveawayRepository = MockGiveawayRepository();
    storageRepository = MockStorageRepository();
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
  });

  CreateGiveawayCubit buildCubit() =>
      CreateGiveawayCubit(giveawayRepository, storageRepository, client);

  group('CreateGiveawayCubit', () {
    blocTest<CreateGiveawayCubit, CreateGiveawayState>(
      'fails fast with no image when there is no admin session, without touching the repository',
      build: buildCubit,
      setUp: () => when(() => auth.currentUser).thenReturn(null),
      act: (cubit) => cubit.publish(
        title: 'iPhone',
        organizerName: 'Org',
        prizeDescription: 'Prize',
        descriptionRules: 'Rules',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 10),
        endTime: '18:00',
      ),
      expect: () => [
        const CreateGiveawayState(status: CreateGiveawayStatus.submitting),
        const CreateGiveawayState(
          status: CreateGiveawayStatus.error,
          failure: UnauthorizedFailure('Your admin session expired. Please sign in again.'),
        ),
      ],
      verify: (_) {
        verifyNever(
          () => giveawayRepository.createGiveaway(
            title: any(named: 'title'),
            organizerName: any(named: 'organizerName'),
            prizeDescription: any(named: 'prizeDescription'),
            descriptionRules: any(named: 'descriptionRules'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            endTime: any(named: 'endTime'),
            createdByAdminId: any(named: 'createdByAdminId'),
          ),
        );
      },
    );

    blocTest<CreateGiveawayCubit, CreateGiveawayState>(
      'publishes without an image, skipping the storage upload entirely',
      build: buildCubit,
      setUp: () {
        when(() => auth.currentUser).thenReturn(_adminUser);
        when(
          () => giveawayRepository.createGiveaway(
            title: 'iPhone',
            organizerName: 'Org',
            prizeDescription: 'Prize',
            descriptionRules: 'Rules',
            imageUrl: null,
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 1, 10),
            endTime: '18:00',
            createdByAdminId: 'admin-1',
          ),
        ).thenAnswer((_) async => Result.success(_giveaway));
      },
      act: (cubit) => cubit.publish(
        title: 'iPhone',
        organizerName: 'Org',
        prizeDescription: 'Prize',
        descriptionRules: 'Rules',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 10),
        endTime: '18:00',
      ),
      expect: () => [
        const CreateGiveawayState(status: CreateGiveawayStatus.submitting),
        const CreateGiveawayState(status: CreateGiveawayStatus.success),
      ],
      verify: (_) {
        verifyNever(
          () => storageRepository.uploadGiveawayImage(
            bytes: any(named: 'bytes'),
            fileExtension: any(named: 'fileExtension'),
          ),
        );
      },
    );
  });
}
