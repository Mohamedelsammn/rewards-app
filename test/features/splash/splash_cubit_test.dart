import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/error/failure.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:rewardsapp/features/splash/presentation/cubit/splash_state.dart';
import 'package:rewardsapp/services/secure_storage_service.dart';
import 'package:rewardsapp/shared/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class FakeSession extends Fake implements Session {}

void main() {
  late MockAuthRepository authRepository;
  late MockSecureStorageService secureStorage;

  setUp(() {
    authRepository = MockAuthRepository();
    secureStorage = MockSecureStorageService();
    when(
      () => authRepository.ensureAnonymousSession(),
    ).thenAnswer((_) async => Result.success(FakeSession()));
  });

  group('SplashCubit', () {
    blocTest<SplashCubit, SplashState>(
      'routes to userHome when a cached user identity + last role exist',
      build: () => SplashCubit(authRepository, secureStorage),
      setUp: () {
        when(() => secureStorage.cachedLastRole).thenAnswer((_) async => 'user');
        when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-123');
      },
      act: (cubit) => cubit.bootstrap(),
      expect: () => [const SplashState(destination: SplashDestination.userHome)],
    );

    blocTest<SplashCubit, SplashState>(
      'routes to roleSelection when there is no cached identity',
      build: () => SplashCubit(authRepository, secureStorage),
      setUp: () {
        when(() => secureStorage.cachedLastRole).thenAnswer((_) async => null);
        when(() => secureStorage.cachedUserId).thenAnswer((_) async => null);
      },
      act: (cubit) => cubit.bootstrap(),
      expect: () => [const SplashState(destination: SplashDestination.roleSelection)],
    );

    blocTest<SplashCubit, SplashState>(
      'still reaches roleSelection even if the anonymous session bootstrap fails '
      '(public browsing works without it)',
      build: () => SplashCubit(authRepository, secureStorage),
      setUp: () {
        when(
          () => authRepository.ensureAnonymousSession(),
        ).thenAnswer((_) async => const Result.failure(ServerFailure()));
        when(() => secureStorage.cachedLastRole).thenAnswer((_) async => null);
        when(() => secureStorage.cachedUserId).thenAnswer((_) async => null);
      },
      act: (cubit) => cubit.bootstrap(),
      expect: () => [const SplashState(destination: SplashDestination.roleSelection)],
    );
  });
}
