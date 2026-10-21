import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../models/user_profile.dart';

/// Wraps the `register-or-link-user` Edge Function -- the only client path
/// allowed to create/link a `public.users` row (implementation-plan.md §14).
///
/// SECURITY (no-OTP phone identity model): this app has no SMS/OTP
/// verification, so a phone number can never be treated as proof that the
/// caller owns it -- it's just a unique application identifier. The server
/// (`fn_register_or_link_user`) binds a phone to whichever authenticated
/// device *first* successfully registers it, and permanently refuses to
/// link any other device to that identity afterwards, even if that other
/// device submits the exact same phone number. A submitted phone that's
/// already taken by a different device fails with
/// [PhoneAlreadyRegisteredElsewhereFailure] and discloses nothing about the
/// existing identity (not its id, name, or anything else).
///
/// Consequence: there is intentionally NO account-recovery path if a user
/// loses or replaces their device in this version -- re-entering their old
/// phone number on a new device will not restore their history. Adding
/// phone-based recovery would require real OTP verification, which is
/// explicitly out of scope for this version.
class UserRepository {
  UserRepository(this._client);

  final SupabaseClient _client;

  /// True if the *current* Supabase session (`auth.uid()`) is linked to a
  /// `user_devices` row -- i.e. whether this device's session still
  /// resolves to a real application identity server-side. Relies entirely
  /// on the existing `user_devices_select_own` RLS policy
  /// (`user_id = fn_current_user_id()`): if the session isn't linked,
  /// `fn_current_user_id()` returns null and RLS transparently returns zero
  /// rows, so no new backend surface is needed to answer this.
  ///
  /// Used to detect a locally-cached identity that has become orphaned
  /// (e.g. the on-device Supabase session was lost/replaced) so the caller
  /// can clear just that stale cache entry rather than the app silently
  /// failing every write with a confusing "not authorized" error.
  Future<Result<bool>> isCurrentDeviceLinked() async {
    try {
      final rows = await _client.from('user_devices').select('id').limit(1);
      return Result.success((rows as List).isNotEmpty);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  Future<Result<UserProfile>> registerOrLink({
    required String fullName,
    required String phone,
    required String countryCode,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'register-or-link-user',
        body: {'fullName': fullName, 'phone': phone, 'countryCode': countryCode},
      );

      final data = response.data;
      if (response.status != 200 || data is! Map) {
        final code = (data is Map ? data['code'] as String? : null) ?? 'server_error';
        final message = data is Map ? data['message'] as String? : null;
        return Result.failure(failureFromEdgeFunctionCode(code, message));
      }

      return Result.success(UserProfile.fromJson(Map<String, dynamic>.from(data)));
    } on FunctionException catch (e) {
      final data = e.details;
      final code = (data is Map ? data['code'] as String? : null) ?? 'server_error';
      final message = data is Map ? data['message'] as String? : e.toString();
      return Result.failure(failureFromEdgeFunctionCode(code, message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  /// Edits the caller's own already-linked profile (Edit Profile). Routed
  /// through `fn_update_user_profile` (a SECURITY DEFINER RPC, not a direct
  /// table UPDATE) so phone normalization and the uniqueness check are both
  /// server-authoritative -- a client-side "looks valid"/"looks unique"
  /// check is never trusted on its own, and a race between two devices
  /// claiming the same number is resolved by the same per-user advisory
  /// lock `fn_register_or_link_user` uses. Never overwrites another
  /// account's phone; a collision fails cleanly with
  /// [PhoneAlreadyInUseFailure] and nothing is committed.
  Future<Result<UserProfile>> updateProfile({
    required String fullName,
    required String phone,
    required String countryCode,
  }) async {
    try {
      final response = await _client.rpc(
        'fn_update_user_profile',
        params: {'p_full_name': fullName, 'p_phone_e164': phone, 'p_country_code': countryCode},
      );

      final rows = response as List;
      if (rows.isEmpty) {
        return const Result.failure(ServerFailure());
      }
      final row = Map<String, dynamic>.from(rows.first as Map);
      if (row['status'] == 'phone_taken') {
        return const Result.failure(PhoneAlreadyInUseFailure());
      }
      return Result.success(UserProfile.fromJson(row));
    } on PostgrestException catch (e) {
      final message = e.message;
      if (message.contains('invalid_phone_number')) {
        return const Result.failure(ValidationFailure('Enter a valid phone number.'));
      }
      if (message.contains('invalid_full_name')) {
        return const Result.failure(ValidationFailure('Enter your full name.'));
      }
      if (message.contains('invalid_country_code')) {
        return const Result.failure(ValidationFailure('Select your country.'));
      }
      if (message.contains('identity_not_linked')) {
        return const Result.failure(UnauthorizedFailure());
      }
      return Result.failure(ServerFailure(message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  /// TRUE self-service account deletion (Google Play "account deletion"
  /// compliance requirement) -- permanently removes this device's linked
  /// participant identity and every piece of personal data tied to it
  /// (profile, devices, participations, notifications), via
  /// `fn_delete_own_account`: a SECURITY DEFINER RPC that resolves the
  /// caller entirely from `auth.uid()` (never a client-supplied id) and
  /// also deletes the underlying `auth.users` row, ending the session
  /// server-side. See
  /// `supabase/migrations/20260813120000_add_account_deletion_function.sql`
  /// for the full dependency map and exactly what is/isn't removed.
  ///
  /// This method only performs the server-side deletion. On success, the
  /// caller is responsible for clearing this device's local state
  /// (`SecureStorageService.clearAll()`, and signing out of the now-defunct
  /// Supabase session) -- mirroring how [registerOrLink]/[updateProfile]
  /// leave local-cache coordination to their own callers rather than doing
  /// it here.
  Future<Result<void>> deleteMyAccount() async {
    try {
      await _client.rpc('fn_delete_own_account');
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(_mapDeleteAccountError(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  Failure _mapDeleteAccountError(String code) {
    switch (code) {
      case 'identity_not_linked':
        return const UnauthorizedFailure('This device is not linked to an account.');
      default:
        return ServerFailure(code);
    }
  }
}
