import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../models/user_profile.dart';

/// Wraps the `register-or-link-user` Edge Function -- the only client path
/// allowed to create/link a `public.users` row (implementation-plan.md §14).
class UserRepository {
  UserRepository(this._client);

  final SupabaseClient _client;

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
}
