import 'dart:async';

import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../error/app_exception.dart';
import '../security/secure_token_storage.dart';
import 'auth_interceptor.dart';
import 'dio_error_mapper.dart';
import 'retry_interceptor.dart';

typedef Json = Map<String, dynamic>;

/// Thin JSON client over Dio. Every method returns the decoded body (an
/// empty map for `204`) or throws [AppException]. Feature data sources are
/// the only callers; presentation never sees Dio.
class ApiClient {
  ApiClient(this._dio);

  factory ApiClient.create({
    required String baseUrl,
    required SecureTokenStorage tokens,
    required void Function(SessionEndReason reason) onSessionEnded,
    HttpClientAdapter? adapter,
  }) {
    BaseOptions options() => BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: AppConstants.requestTimeout,
      receiveTimeout: AppConstants.requestTimeout,
      sendTimeout: AppConstants.requestTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: {'Accept': 'application/json'},
    );
    final refreshDio = Dio(options());
    final dio = Dio(options());
    if (adapter != null) {
      refreshDio.httpClientAdapter = adapter;
      dio.httpClientAdapter = adapter;
    }
    final auth = AuthInterceptor(
      tokens: tokens,
      refreshDio: refreshDio,
      onSessionEnded: onSessionEnded,
    )..retryDio = dio;
    dio.interceptors.addAll([auth, RetryInterceptor(dio: dio)]);
    return ApiClient(dio);
  }

  final Dio _dio;

  Future<Json> get(String path, {Map<String, dynamic>? query, bool auth = true}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: _clean(query), options: _options(auth)));

  Future<Json> post(String path, {Object? body, bool auth = true, Map<String, String>? headers}) =>
      _send(
        () => _dio.post<dynamic>(path, data: body ?? const {}, options: _options(auth, headers)),
      );

  Future<Json> patch(String path, {Object? body}) =>
      _send(() => _dio.patch<dynamic>(path, data: body ?? const {}, options: _options(true)));

  Future<Json> put(String path, {Object? body}) =>
      _send(() => _dio.put<dynamic>(path, data: body ?? const {}, options: _options(true)));

  Future<Json> delete(String path, {Object? body}) =>
      _send(() => _dio.delete<dynamic>(path, data: body, options: _options(true)));

  Options _options(bool auth, [Map<String, String>? headers]) {
    final options = Options(headers: headers);
    return auth ? options : publicOptions(options);
  }

  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    return {
      for (final entry in query.entries)
        if (entry.value != null && '${entry.value}'.isNotEmpty) entry.key: entry.value,
    };
  }

  Future<Json> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      final data = response.data;
      if (data == null || (data is String && data.isEmpty)) return const {};
      if (data is Map) return Map<String, dynamic>.from(data);
      throw const AppException(code: AppException.badResponse, message: 'Expected a JSON object');
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}
