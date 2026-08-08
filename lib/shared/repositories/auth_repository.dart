import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';

/// Anonymous sign-in bootstrap (the security principal for every regular
/// user device, implementation-plan.md §1.4 #2) plus admin email/password
/// auth and admin self-service sign-up.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<Result<Session>> ensureAnonymousSession() async {
    final existing = _client.auth.currentSession;
    if (existing != null) return Result.success(existing);

    try {
      final response = await _client.auth.signInAnonymously();
      final session = response.session;
      if (session == null) {
        return const Result.failure(ServerFailure('Could not start a session.'));
      }
      return Result.success(session);
    } on AuthException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  Future<Result<Session>> signInAdmin({required String email, required String password}) async {
    try {
      final response = await _client.auth.signInWithPassword(email: email, password: password);
      final session = response.session;
      if (session == null) {
        return const Result.failure(UnauthorizedFailure('Invalid email or password.'));
      }

      final isAdmin = await _checkIsAdmin();
      if (!isAdmin) {
        await _client.auth.signOut();
        return const Result.failure(
          UnauthorizedFailure('This account does not have admin access.'),
        );
      }

      return Result.success(session);
    } on AuthException catch (e) {
      return Result.failure(UnauthorizedFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  /// Self-service admin registration -- gated server-side by a shared access
  /// code (see the `admin-sign-up` Edge Function / `fn_verify_admin_signup_code`).
  /// Selecting "Admin" in the app grants zero privilege by itself; only a
  /// caller who also knows the access code ends up with an `admin_users` row.
  /// On success, immediately signs the new admin in so callers land straight
  /// on the dashboard, reusing the same `fn_is_admin()` check as `signInAdmin`.
  Future<Result<Session>> signUpAdmin({
    required String email,
    required String password,
    required String fullName,
    required String accessCode,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'admin-sign-up',
        body: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'accessCode': accessCode,
        },
      );

      final data = response.data;
      if (response.status != 200 || data is! Map || data['userId'] == null) {
        final code = (data is Map ? data['code'] as String? : null) ?? 'server_error';
        final message = data is Map ? data['message'] as String? : null;
        return Result.failure(_mapAdminSignUpError(code, message));
      }

      return signInAdmin(email: email, password: password);
    } on FunctionException catch (e) {
      final data = e.details;
      final code = (data is Map ? data['code'] as String? : null) ?? 'server_error';
      final message = data is Map ? data['message'] as String? : e.toString();
      return Result.failure(_mapAdminSignUpError(code, message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  Failure _mapAdminSignUpError(String code, String? message) {
    switch (code) {
      case 'invalid_access_code':
        return const UnauthorizedFailure('Invalid admin access code.');
      case 'email_already_registered':
        return const ValidationFailure('An account with this email already exists.');
      case 'invalid_email':
        return const ValidationFailure('Enter a valid email address.');
      case 'invalid_password':
        return ValidationFailure(message ?? 'Password must be at least 8 characters.');
      case 'invalid_full_name':
        return const ValidationFailure('Enter your full name.');
      default:
        return ServerFailure(message ?? 'Something went wrong. Please try again.');
    }
  }

  Future<bool> _checkIsAdmin() async {
    try {
      final result = await _client.rpc('fn_is_admin');
      return result == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() => _client.auth.signOut();
}
