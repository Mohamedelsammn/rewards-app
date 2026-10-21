import 'package:dio/dio.dart';

/// Retries idempotent `GET` requests on transient failures (connection
/// errors, timeouts, 502/503/504) with a short linear backoff. Writes are
/// never retried automatically; orders use an explicit idempotency key and a
/// user-initiated retry instead.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 400),
  });

  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;

  static const _attemptKey = 'retryAttempt';

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;
    if (options.method != 'GET' || attempt >= maxRetries || !_isTransient(err)) {
      return handler.next(err);
    }
    await Future<void>.delayed(baseDelay * (attempt + 1));
    options.extra[_attemptKey] = attempt + 1;
    try {
      handler.resolve(await dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _isTransient(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return true;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 0;
        return status == 502 || status == 503 || status == 504;
      default:
        return false;
    }
  }
}
