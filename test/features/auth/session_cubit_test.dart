import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/core/error/app_exception.dart';
import 'package:rewardsapp/core/network/auth_interceptor.dart';
import 'package:rewardsapp/features/auth/domain/entities/app_user.dart';
import 'package:rewardsapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:rewardsapp/features/auth/presentation/bloc/session_cubit.dart';

const _user = AppUser(id: 'u1', email: 'a@b.co', name: 'A', language: 'en', status: 'ACTIVE');

class _Auth implements AuthRepository {
  _Auth({this.stored = true, this.restoreError});

  bool stored;
  final Object? restoreError;
  final calls = <String>[];

  @override
  Future<bool> hasStoredSession() async => stored;

  @override
  Future<AppUser> restoreSession() async {
    if (restoreError != null) throw restoreError!;
    return _user;
  }

  @override
  Future<void> logout() async => calls.add('logout');

  @override
  Future<void> clearLocalSession() async => calls.add('clear');

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('no stored tokens: signed out without a network call', () async {
    final cubit = SessionCubit(_Auth(stored: false));
    await cubit.restore();
    expect(cubit.state.status, SessionStatus.unauthenticated);
  });

  test('restores the user from stored tokens', () async {
    final cubit = SessionCubit(_Auth());
    await cubit.restore();
    expect(cubit.state.isAuthenticated, isTrue);
    expect(cubit.state.user, _user);
  });

  test('offline restore keeps the tokens', () async {
    final auth = _Auth(restoreError: const AppException(code: AppException.network));
    final cubit = SessionCubit(auth);
    await cubit.restore();
    expect(cubit.state.status, SessionStatus.offline);
    expect(auth.calls, isEmpty);
  });

  test('a suspended account is signed out with a reason', () async {
    final auth = _Auth(
      restoreError: const AppException(code: 'ACCOUNT_SUSPENDED', statusCode: 403),
    );
    final cubit = SessionCubit(auth);
    await cubit.restore();
    expect(cubit.state.status, SessionStatus.unauthenticated);
    expect(cubit.state.endReason, SessionEndReason.suspended);
    expect(auth.calls, ['clear']);
  });

  test('sign out unregisters push before logging out', () async {
    final order = <String>[];
    final auth = _Auth();
    final cubit = SessionCubit(auth, beforeSignOut: () async => order.add('unregister'));
    cubit.signedIn(_user);
    await cubit.signOut();
    order.addAll(auth.calls);
    expect(order, ['unregister', 'logout']);
    expect(cubit.state.status, SessionStatus.unauthenticated);
  });

  test('stats updates keep the user', () {
    final cubit = SessionCubit(_Auth())..signedIn(_user);
    cubit.updateStats(points: 700, orders: 2);
    expect(cubit.state.user?.stats.points, 700);
    expect(cubit.state.user?.stats.orders, 2);
    expect(cubit.state.user?.name, 'A');
  });
}
