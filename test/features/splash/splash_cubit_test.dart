import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:rewardsapp/features/splash/presentation/cubit/splash_state.dart';
import 'package:rewardsapp/services/secure_storage_service.dart';
import 'package:rewardsapp/services/user_identity_service.dart';
import 'package:rewardsapp/shared/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockUserIdentityService extends Mock implements UserIdentityService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockUserIdentityService userIdentityService;
  late MockSecureStorageService secureStorage;
  late MockAuthRepository authRepository;

  setUp(() {
    userIdentityService = MockUserIdentityService();
    secureStorage = MockSecureStorageService();
    authRepository = MockAuthRepository();
    when(() => userIdentityService.restoreAndVerify()).thenAnswer((_) async {});
  });

  // minVisibleDuration: Duration.zero -- these tests only assert which
  // destination bootstrap() resolves to, not how long it stays on screen
  // (that's the production default of ~3s, deliberately not exercised here
  // to keep the suite fast).
  SplashCubit buildCubit() => SplashCubit(
    userIdentityService,
    secureStorage,
    authRepository,
    minVisibleDuration: Duration.zero,
  );

  group('SplashCubit', () {
    blocTest<SplashCubit, SplashState>(
      'routes to userHome when a cached user identity + last role exist',
      build: buildCubit,
      setUp: () {
        when(() => secureStorage.cachedLastRole).thenAnswer((_) async => 'user');
        when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-123');
      },
      act: (cubit) => cubit.bootstrap(),
      expect: () => [const SplashState(destination: SplashDestination.userHome)],
      verify: (_) {
        verify(() => userIdentityService.restoreAndVerify()).called(1);
      },
    );

    blocTest<SplashCubit, SplashState>(
      'routes to roleSelection when there is no cached identity',
      build: buildCubit,
      setUp: () {
        when(() => secureStorage.cachedLastRole).thenAnswer((_) async => null);
        when(() => secureStorage.cachedUserId).thenAnswer((_) async => null);
      },
      act: (cubit) => cubit.bootstrap(),
      expect: () => [const SplashState(destination: SplashDestination.roleSelection)],
    );

    blocTest<SplashCubit, SplashState>(
      'routes to roleSelection (not a stale userHome auto-skip) when '
      'restoreAndVerify already cleared an orphaned cached identity',
      build: buildCubit,
      setUp: () {
        // Simulates UserIdentityService having detected a session that's no
        // longer linked to the cached identity and clearing it -- by the
        // time bootstrap() reads cachedUserId, it's already gone, so
        // Splash must NOT auto-skip into a User Home that would show no
        // data.
        when(() => secureStorage.cachedLastRole).thenAnswer((_) async => 'user');
        when(() => secureStorage.cachedUserId).thenAnswer((_) async => null);
      },
      act: (cubit) => cubit.bootstrap(),
      expect: () => [const SplashState(destination: SplashDestination.roleSelection)],
    );

    blocTest<SplashCubit, SplashState>(
      'routes to adminShell when the last role is admin and a real (non-anonymous) '
      'session is still active',
      build: buildCubit,
      setUp: () {
        when(() => secureStorage.cachedLastRole).thenAnswer((_) async => 'admin');
        when(() => authRepository.currentSession).thenReturn(
          Session(
            accessToken: 'token',
            tokenType: 'bearer',
            user: const User(
              id: 'admin-1',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: '2026-01-01T00:00:00Z',
            ),
          ),
        );
      },
      act: (cubit) => cubit.bootstrap(),
      expect: () => [const SplashState(destination: SplashDestination.adminShell)],
      verify: (_) {
        verifyNever(() => secureStorage.clearLastRole());
      },
    );

    blocTest<SplashCubit, SplashState>(
      'clears the stale admin role and routes to roleSelection when the last role is admin '
      'but the session is gone (expired/signed out elsewhere)',
      build: buildCubit,
      setUp: () {
        when(() => secureStorage.cachedLastRole).thenAnswer((_) async => 'admin');
        when(() => authRepository.currentSession).thenReturn(null);
        when(() => secureStorage.clearLastRole()).thenAnswer((_) async {});
      },
      act: (cubit) => cubit.bootstrap(),
      expect: () => [const SplashState(destination: SplashDestination.roleSelection)],
      verify: (_) {
        verify(() => secureStorage.clearLastRole()).called(1);
      },
    );

    blocTest<SplashCubit, SplashState>(
      'clears the stale admin role when the only session left is the shared anonymous one '
      '(the admin session was lost, not merely evicted by a User session)',
      build: buildCubit,
      setUp: () {
        when(() => secureStorage.cachedLastRole).thenAnswer((_) async => 'admin');
        when(() => authRepository.currentSession).thenReturn(
          Session(
            accessToken: 'token',
            tokenType: 'bearer',
            user: const User(
              id: 'anon-1',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: '2026-01-01T00:00:00Z',
              isAnonymous: true,
            ),
          ),
        );
        when(() => secureStorage.clearLastRole()).thenAnswer((_) async {});
      },
      act: (cubit) => cubit.bootstrap(),
      expect: () => [const SplashState(destination: SplashDestination.roleSelection)],
      verify: (_) {
        verify(() => secureStorage.clearLastRole()).called(1);
      },
    );
  });
}
