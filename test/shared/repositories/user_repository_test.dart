import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/error/failure.dart';
import 'package:rewardsapp/shared/repositories/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

/// A Future-compatible stand-in for the real network-calling
/// `PostgrestFilterBuilder<dynamic>` that `SupabaseClient.rpc()` returns --
/// resolves to [value] as soon as it's awaited, without any real HTTP call.
class _FakePostgrestFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  _FakePostgrestFilterBuilder(this.value);
  final T value;

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) =>
      Future.value(value).then(onValue, onError: onError);
}

/// Covers [UserRepository.deleteMyAccount] -- the Flutter side of the
/// Google Play account-deletion requirement. The actual deletion logic
/// lives entirely server-side in `fn_delete_own_account` (a SECURITY
/// DEFINER RPC that resolves the caller from auth.uid(), never a
/// client-supplied id -- see
/// supabase/migrations/20260813120000_add_account_deletion_function.sql).
/// This suite only verifies the repository calls that RPC by name, with no
/// arguments (there is nothing for the client to supply -- the server
/// derives everything from the caller's own session), and maps its
/// success/failure outcomes correctly. It never asserts anything about what
/// the RPC deletes -- that's a database-level concern, exercised by
/// supabase/verification/account_deletion_checks.sql instead.
void main() {
  late MockSupabaseClient client;
  late UserRepository repository;

  setUp(() {
    client = MockSupabaseClient();
    repository = UserRepository(client);
  });

  group('UserRepository.deleteMyAccount', () {
    test('calls fn_delete_own_account with no arguments and reports success '
        'when the server confirms it', () async {
      when(
        () => client.rpc('fn_delete_own_account'),
      ).thenAnswer((_) => _FakePostgrestFilterBuilder<dynamic>(null));

      final result = await repository.deleteMyAccount();

      expect(result.isSuccess, isTrue);
      verify(() => client.rpc('fn_delete_own_account')).called(1);
    });

    test('maps identity_not_linked to UnauthorizedFailure -- e.g. this '
        "session isn't linked to any participant identity (an admin "
        'session, or a brand-new device that never registered)', () async {
      when(
        () => client.rpc('fn_delete_own_account'),
      ).thenThrow(const PostgrestException(message: 'identity_not_linked'));

      final result = await repository.deleteMyAccount();

      expect(result.fold((f) => f, (_) => null), isA<UnauthorizedFailure>());
    });

    test('maps an unrecognized server error to ServerFailure rather than '
        'silently succeeding', () async {
      when(
        () => client.rpc('fn_delete_own_account'),
      ).thenThrow(const PostgrestException(message: 'some_other_db_error'));

      final result = await repository.deleteMyAccount();

      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    });

    test('maps a network-level failure (no PostgrestException) to '
        'NetworkFailure', () async {
      when(() => client.rpc('fn_delete_own_account')).thenThrow(Exception('offline'));

      final result = await repository.deleteMyAccount();

      expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
    });
  });
}
