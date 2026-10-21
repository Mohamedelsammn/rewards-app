import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/error/failure.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/services/notification_service.dart';
import 'package:rewardsapp/services/secure_storage_service.dart';
import 'package:rewardsapp/services/user_identity_service.dart';
import 'package:rewardsapp/shared/repositories/auth_repository.dart';
import 'package:rewardsapp/shared/repositories/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockNotificationService extends Mock implements NotificationService {}

class FakeSession extends Fake implements Session {}

/// Covers the fix for "sign out then continue as user loses participations":
/// UserIdentityService is what Splash/Role Selection now call instead of a
/// bare `ensureAnonymousSession()`, and it's the layer responsible for
/// telling a genuinely-orphaned local identity apart from a perfectly valid
/// one that must survive Sign Out untouched.
void main() {
  late MockAuthRepository authRepository;
  late MockUserRepository userRepository;
  late MockSecureStorageService secureStorage;
  late MockNotificationService notificationService;
  late UserIdentityService service;

  setUp(() {
    authRepository = MockAuthRepository();
    userRepository = MockUserRepository();
    secureStorage = MockSecureStorageService();
    notificationService = MockNotificationService();
    service = UserIdentityService(
      authRepository,
      userRepository,
      secureStorage,
      notificationService,
    );

    when(
      () => authRepository.ensureAnonymousSession(),
    ).thenAnswer((_) async => Result.success(FakeSession()));
    when(() => authRepository.currentSession).thenReturn(FakeSession());
    when(() => secureStorage.clearIdentity()).thenAnswer((_) async {});
    when(() => notificationService.registerDeviceToken()).thenAnswer((_) async {});
  });

  group('UserIdentityService.restoreAndVerify', () {
    test('always ensures a session first', () async {
      when(() => secureStorage.cachedUserId).thenAnswer((_) async => null);

      await service.restoreAndVerify();

      verify(() => authRepository.ensureAnonymousSession()).called(1);
    });

    test('does nothing further when there is no cached identity to verify', () async {
      when(() => secureStorage.cachedUserId).thenAnswer((_) async => null);

      await service.restoreAndVerify();

      verifyNever(() => userRepository.isCurrentDeviceLinked());
      verifyNever(() => secureStorage.clearIdentity());
      verifyNever(() => notificationService.registerDeviceToken());
    });

    test('a cached identity that is still linked survives untouched -- this is the '
        'sign-out-preserves-data guarantee', () async {
      when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-123');
      when(
        () => userRepository.isCurrentDeviceLinked(),
      ).thenAnswer((_) async => const Result.success(true));

      await service.restoreAndVerify();

      verifyNever(() => secureStorage.clearIdentity());
    });

    test('a cached identity confirmed orphaned by the server is cleared', () async {
      when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-123');
      when(
        () => userRepository.isCurrentDeviceLinked(),
      ).thenAnswer((_) async => const Result.success(false));

      await service.restoreAndVerify();

      verify(() => secureStorage.clearIdentity()).called(1);
    });

    test('a network/server failure while checking linkage is treated as "unknown," '
        'never as "unlinked" -- a connectivity blip must never wipe valid data', () async {
      when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-123');
      when(
        () => userRepository.isCurrentDeviceLinked(),
      ).thenAnswer((_) async => const Result.failure(NetworkFailure()));

      await service.restoreAndVerify();

      verifyNever(() => secureStorage.clearIdentity());
    });
  });

  group('UserIdentityService.restoreAndVerify -- FCM device-token registration', () {
    // Regression coverage for: a real Android device joins a giveaway and
    // receives the in-app winner celebration correctly, but
    // admin-select-winner logs "no device with a registered FCM token."
    // Root cause: NotificationService.initialize() (called once from
    // main(), before this method has ever run) can fetch a token before
    // this device's session/identity is established, so the
    // auth.uid()-gated user_devices write silently no-ops and is never
    // retried. This is the fix: re-attempt registration here, which runs on
    // every entry into User mode.
    test(
      'registers the device token once the identity is confirmed valid and still linked',
      () async {
        when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-123');
        when(
          () => userRepository.isCurrentDeviceLinked(),
        ).thenAnswer((_) async => const Result.success(true));

        await service.restoreAndVerify();

        verify(() => notificationService.registerDeviceToken()).called(1);
      },
    );

    test('does NOT register a token for an identity the server just confirmed orphaned -- '
        'nothing valid to register against', () async {
      when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-123');
      when(
        () => userRepository.isCurrentDeviceLinked(),
      ).thenAnswer((_) async => const Result.success(false));

      await service.restoreAndVerify();

      verifyNever(() => notificationService.registerDeviceToken());
    });

    test('still registers a token when the linkage check itself fails -- a connectivity blip '
        'on that one check should not also block token registration for an otherwise-trusted '
        'cached identity', () async {
      when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-123');
      when(
        () => userRepository.isCurrentDeviceLinked(),
      ).thenAnswer((_) async => const Result.failure(NetworkFailure()));

      await service.restoreAndVerify();

      verify(() => notificationService.registerDeviceToken()).called(1);
    });

    test('does NOT register a token when the session never attached to the client', () async {
      when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-123');
      when(() => authRepository.currentSession).thenReturn(null);

      await service.restoreAndVerify();

      verifyNever(() => notificationService.registerDeviceToken());
    });
  });

  group('UserIdentityService.restoreAndVerify -- same-device Admin -> User session attachment', () {
    // Regression coverage for: Admin selects a User as winner, signs out, the
    // User re-enters on the same device, and the celebration never appears.
    // Root cause: AuthRepository.ensureAnonymousSession() can report success
    // (it always returns the session data it fetched) while the Supabase
    // client's own internal "current session" was never actually updated --
    // the client discards a freshly-restored session if it detects the
    // session changed concurrently, which can happen right after the prior
    // Admin session was torn down. The old restoreAndVerify() trusted a
    // successful Result alone and immediately ran the linked-device check,
    // which -- with no real auth.uid() attached -- came back empty and
    // wrongly wiped a perfectly valid cached identity, permanently losing
    // the one chance to show the pending winner celebration.
    test('a session that resolves successfully but never actually attaches to the client is '
        'retried once, and the linked-device check never runs (nor is the cache wiped) if it '
        'stays unattached', () async {
      when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-123');
      when(() => authRepository.currentSession).thenReturn(null);

      await service.restoreAndVerify();

      verify(() => authRepository.ensureAnonymousSession()).called(2);
      verifyNever(() => userRepository.isCurrentDeviceLinked());
      verifyNever(() => secureStorage.clearIdentity());
    });

    test('a session unattached on the first attempt but attached by the retry proceeds normally, '
        'exactly as if it had attached the first time', () async {
      when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-123');
      var callCount = 0;
      when(() => authRepository.currentSession).thenAnswer((_) {
        callCount++;
        return callCount == 1 ? null : FakeSession();
      });
      when(
        () => userRepository.isCurrentDeviceLinked(),
      ).thenAnswer((_) async => const Result.success(true));

      await service.restoreAndVerify();

      verify(() => authRepository.ensureAnonymousSession()).called(2);
      verify(() => userRepository.isCurrentDeviceLinked()).called(1);
      verifyNever(() => secureStorage.clearIdentity());
    });

    test('ensureAnonymousSession itself failing outright is also treated as unattached -- '
        'no linked-device check, no cache wipe', () async {
      when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-123');
      when(
        () => authRepository.ensureAnonymousSession(),
      ).thenAnswer((_) async => const Result.failure(NetworkFailure()));

      await service.restoreAndVerify();

      verifyNever(() => userRepository.isCurrentDeviceLinked());
      verifyNever(() => secureStorage.clearIdentity());
    });
  });
}
