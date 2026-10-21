import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/services/secure_storage_service.dart';
import 'package:rewardsapp/shared/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

const _anonUser = User(
  id: 'anon-user-1',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
  isAnonymous: true,
);

const _adminUser = User(
  id: 'admin-1',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

final _anonSession = Session(
  accessToken: 'fake-anon-access-token',
  refreshToken: 'anon-refresh-1',
  tokenType: 'bearer',
  user: _anonUser,
);

/// Regression coverage for "join giveaway -> sign out -> Admin signs in on
/// the same device -> Admin signs out -> User returns -> My Giveaways is
/// empty": root-caused to GoTrue holding exactly one session per client, so
/// an Admin sign-in on this shared client silently evicted the User's
/// anonymous session, and Admin sign-out destroyed it outright -- the next
/// `ensureAnonymousSession()` then minted a brand-new anonymous auth.uid()
/// with no link to the device's existing `user_devices`/`participations`
/// rows. These tests cover the standby-refresh-token fix in AuthRepository.
void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late MockSecureStorageService secureStorage;
  late AuthRepository repository;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    secureStorage = MockSecureStorageService();
    when(() => client.auth).thenReturn(auth);
    repository = AuthRepository(client, secureStorage);
  });

  group('ensureAnonymousSession', () {
    test('an already-active anonymous session is reused and its refresh '
        'token is kept fresh in the standby cache', () async {
      when(() => auth.currentSession).thenReturn(_anonSession);
      when(() => secureStorage.saveAnonymousRefreshToken(any())).thenAnswer((_) async {});

      final result = await repository.ensureAnonymousSession();

      expect(result.fold((_) => null, (s) => s), _anonSession);
      verify(() => secureStorage.saveAnonymousRefreshToken('anon-refresh-1')).called(1);
      verifyNever(() => auth.signInAnonymously());
    });

    test('no active session but a preserved anonymous refresh token exists '
        '-- restores the SAME identity via setSession instead of minting a '
        'new one', () async {
      when(() => auth.currentSession).thenReturn(null);
      when(
        () => secureStorage.cachedAnonymousRefreshToken,
      ).thenAnswer((_) async => 'anon-refresh-1');
      when(
        () => auth.setSession('anon-refresh-1'),
      ).thenAnswer((_) async => AuthResponse(session: _anonSession));
      when(() => secureStorage.saveAnonymousRefreshToken(any())).thenAnswer((_) async {});

      final result = await repository.ensureAnonymousSession();

      expect(result.fold((_) => null, (s) => s), _anonSession);
      verify(() => auth.setSession('anon-refresh-1')).called(1);
      verifyNever(() => auth.signInAnonymously());
    });

    test('no active session and no preserved token -- falls back to minting '
        'a fresh anonymous session (first-ever launch behavior, unchanged)', () async {
      when(() => auth.currentSession).thenReturn(null);
      when(() => secureStorage.cachedAnonymousRefreshToken).thenAnswer((_) async => null);
      when(
        () => auth.signInAnonymously(),
      ).thenAnswer((_) async => AuthResponse(session: _anonSession));
      when(() => secureStorage.saveAnonymousRefreshToken(any())).thenAnswer((_) async {});

      final result = await repository.ensureAnonymousSession();

      expect(result.fold((_) => null, (s) => s), _anonSession);
      verify(() => auth.signInAnonymously()).called(1);
    });

    test('a preserved refresh token that the server rejects (expired/revoked) '
        'is cleared and falls back to minting a fresh session rather than '
        'failing outright', () async {
      when(() => auth.currentSession).thenReturn(null);
      when(
        () => secureStorage.cachedAnonymousRefreshToken,
      ).thenAnswer((_) async => 'stale-refresh');
      when(() => auth.setSession('stale-refresh')).thenThrow(const AuthException('invalid'));
      when(() => secureStorage.clearAnonymousRefreshToken()).thenAnswer((_) async {});
      when(
        () => auth.signInAnonymously(),
      ).thenAnswer((_) async => AuthResponse(session: _anonSession));
      when(() => secureStorage.saveAnonymousRefreshToken(any())).thenAnswer((_) async {});

      final result = await repository.ensureAnonymousSession();

      expect(result.fold((_) => null, (s) => s), _anonSession);
      verify(() => secureStorage.clearAnonymousRefreshToken()).called(1);
      verify(() => auth.signInAnonymously()).called(1);
    });
  });

  group('signInAdmin', () {
    test('preserves the active anonymous session\'s refresh token before '
        'the Admin sign-in overwrites it on this shared client', () async {
      when(() => auth.currentSession).thenReturn(_anonSession);
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('invalid credentials'));
      when(() => secureStorage.saveAnonymousRefreshToken(any())).thenAnswer((_) async {});

      await repository.signInAdmin(email: 'admin@example.com', password: 'secret123');

      verify(() => secureStorage.saveAnonymousRefreshToken('anon-refresh-1')).called(1);
    });

    test('does not attempt to preserve a token when there is no active '
        'anonymous session to preserve', () async {
      when(() => auth.currentSession).thenReturn(null);
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('invalid credentials'));

      await repository.signInAdmin(email: 'admin@example.com', password: 'secret123');

      verifyNever(() => secureStorage.saveAnonymousRefreshToken(any()));
    });

    test('an already-Admin session is not mistaken for an anonymous one to '
        'preserve', () async {
      final adminSession = Session(
        accessToken: 'fake-admin-access-token',
        refreshToken: 'admin-refresh-1',
        tokenType: 'bearer',
        user: _adminUser,
      );
      when(() => auth.currentSession).thenReturn(adminSession);
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('invalid credentials'));

      await repository.signInAdmin(email: 'admin@example.com', password: 'secret123');

      verifyNever(() => secureStorage.saveAnonymousRefreshToken(any()));
    });
  });
}
