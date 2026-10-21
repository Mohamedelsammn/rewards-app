import 'dart:async';

import 'package:dio/dio.dart';

import '../security/secure_token_storage.dart';
import 'dio_error_mapper.dart';

/// Why the session ended without the user signing out.
enum SessionEndReason { refreshRejected, suspended }

/// Attaches the bearer token and transparently refreshes it.
///
/// - Exactly one refresh runs at a time; concurrent `401`s wait on the same
///   [Completer] and then retry once with the new token.
/// - A `401` for a request that was sent with an access token that has since
///   been replaced is retried with the stored token without refreshing again.
/// - `409 REFRESH_ALREADY_ROTATED` means another request already rotated the
///   refresh token: reload the stored tokens and retry.
/// - `401 INVALID_REFRESH_TOKEN` (or a suspended account) clears the tokens and
///   reports the end of the session through [onSessionEnded].
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokens, required this.refreshDio, required this.onSessionEnded});

  final SecureTokenStorage tokens;

  /// A bare client (no interceptors) used only for `POST /auth/refresh`.
  final Dio refreshDio;
  final void Function(SessionEndReason reason) onSessionEnded;

  /// The client whose requests are retried; set after construction because
  /// the interceptor is added to that same client.
  late Dio retryDio;

  Completer<bool>? _refreshing;

  static const _authKey = 'auth';
  static const _sentTokenKey = 'sentAccessToken';
  static const _retriedKey = 'authRetried';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra[_authKey] != false) {
      final token = await tokens.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        options.extra[_sentTokenKey] = token;
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final code = apiErrorCode(err.response?.data);
    final shouldRefresh =
        err.response?.statusCode == 401 &&
        options.extra[_authKey] != false &&
        options.extra[_retriedKey] != true &&
        options.extra[_sentTokenKey] != null &&
        (code == 'TOKEN_EXPIRED' || code == 'UNAUTHENTICATED');
    if (!shouldRefresh) return handler.next(err);

    final current = await tokens.accessToken;
    final tokenChanged = current != null && current != options.extra[_sentTokenKey];
    final ok = tokenChanged || await _refresh();
    if (!ok) return handler.next(err);
    try {
      options.extra[_retriedKey] = true;
      handler.resolve(await retryDio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool> _refresh() {
    final running = _refreshing;
    if (running != null) return running.future;
    final completer = Completer<bool>();
    _refreshing = completer;
    _performRefresh()
        .catchError((Object _) => false)
        .then(completer.complete)
        .whenComplete(() => _refreshing = null);
    return completer.future;
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await tokens.refreshToken;
    if (refreshToken == null) return false;
    try {
      final response = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final pair = response.data?['tokens'];
      if (pair is! Map) return false;
      await tokens.saveTokens(
        accessToken: pair['accessToken'] as String,
        refreshToken: pair['refreshToken'] as String,
      );
      return true;
    } on DioException catch (error) {
      final code = apiErrorCode(error.response?.data);
      if (code == 'REFRESH_ALREADY_ROTATED') {
        await tokens.reload();
        final reloaded = await tokens.refreshToken;
        return reloaded != null && reloaded != refreshToken;
      }
      if (code == 'INVALID_REFRESH_TOKEN' || code == 'ACCOUNT_SUSPENDED') {
        await tokens.clearTokens();
        onSessionEnded(
          code == 'ACCOUNT_SUSPENDED'
              ? SessionEndReason.suspended
              : SessionEndReason.refreshRejected,
        );
      }
      // Network failures keep the session; the original error is surfaced.
      return false;
    }
  }
}

/// Marks a request as public so no bearer token is attached or refreshed.
Options publicOptions([Options? options]) =>
    (options ?? Options()).copyWith(extra: {...?options?.extra, AuthInterceptor._authKey: false});
