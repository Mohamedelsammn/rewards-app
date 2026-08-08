import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/error/failure.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/admin_auth/presentation/bloc/admin_auth_cubit.dart';
import 'package:rewardsapp/features/admin_auth/presentation/bloc/admin_auth_state.dart';
import 'package:rewardsapp/shared/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeSession extends Fake implements Session {}

void main() {
  late MockAuthRepository authRepository;

  setUp(() => authRepository = MockAuthRepository());

  group('AdminAuthCubit', () {
    blocTest<AdminAuthCubit, AdminAuthState>(
      'emits submitting then success on valid admin credentials',
      build: () => AdminAuthCubit(authRepository),
      setUp: () => when(
        () => authRepository.signInAdmin(
          email: 'admin@rewardsapp.test',
          password: 'correct-password',
        ),
      ).thenAnswer((_) async => Result.success(FakeSession())),
      act: (cubit) => cubit.signIn(email: 'admin@rewardsapp.test', password: 'correct-password'),
      expect: () => [
        const AdminAuthState(status: AdminAuthStatus.submitting),
        const AdminAuthState(status: AdminAuthStatus.success),
      ],
    );

    blocTest<AdminAuthCubit, AdminAuthState>(
      'emits submitting then error when the account has no admin access',
      build: () => AdminAuthCubit(authRepository),
      setUp: () =>
          when(
            () => authRepository.signInAdmin(email: 'user@example.com', password: 'wrong'),
          ).thenAnswer(
            (_) async => const Result.failure(
              UnauthorizedFailure('This account does not have admin access.'),
            ),
          ),
      act: (cubit) => cubit.signIn(email: 'user@example.com', password: 'wrong'),
      expect: () => [
        const AdminAuthState(status: AdminAuthStatus.submitting),
        const AdminAuthState(
          status: AdminAuthStatus.error,
          failure: UnauthorizedFailure('This account does not have admin access.'),
        ),
      ],
    );

    blocTest<AdminAuthCubit, AdminAuthState>(
      'signUp emits submitting then success with a valid access code',
      build: () => AdminAuthCubit(authRepository),
      setUp: () => when(
        () => authRepository.signUpAdmin(
          email: 'newadmin@rewardsapp.test',
          password: 'SuperSecret123',
          fullName: 'New Admin',
          accessCode: 'VALID-CODE',
        ),
      ).thenAnswer((_) async => Result.success(FakeSession())),
      act: (cubit) => cubit.signUp(
        email: 'newadmin@rewardsapp.test',
        password: 'SuperSecret123',
        fullName: 'New Admin',
        accessCode: 'VALID-CODE',
      ),
      expect: () => [
        const AdminAuthState(status: AdminAuthStatus.submitting),
        const AdminAuthState(status: AdminAuthStatus.success),
      ],
    );

    blocTest<AdminAuthCubit, AdminAuthState>(
      'signUp emits submitting then error with an invalid access code -- '
      'selecting Admin never grants privilege on its own',
      build: () => AdminAuthCubit(authRepository),
      setUp: () =>
          when(
            () => authRepository.signUpAdmin(
              email: 'nobody@example.com',
              password: 'SuperSecret123',
              fullName: 'Nobody',
              accessCode: 'WRONG-CODE',
            ),
          ).thenAnswer(
            (_) async => const Result.failure(UnauthorizedFailure('Invalid admin access code.')),
          ),
      act: (cubit) => cubit.signUp(
        email: 'nobody@example.com',
        password: 'SuperSecret123',
        fullName: 'Nobody',
        accessCode: 'WRONG-CODE',
      ),
      expect: () => [
        const AdminAuthState(status: AdminAuthStatus.submitting),
        const AdminAuthState(
          status: AdminAuthStatus.error,
          failure: UnauthorizedFailure('Invalid admin access code.'),
        ),
      ],
    );

    blocTest<AdminAuthCubit, AdminAuthState>(
      'reset clears error/submitting state back to idle',
      build: () => AdminAuthCubit(authRepository),
      seed: () =>
          const AdminAuthState(status: AdminAuthStatus.error, failure: UnauthorizedFailure()),
      act: (cubit) => cubit.reset(),
      expect: () => [const AdminAuthState()],
    );
  });
}
