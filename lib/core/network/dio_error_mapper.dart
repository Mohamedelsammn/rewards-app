import 'package:dio/dio.dart';

import '../error/app_exception.dart';

/// Reads the stable error code from the API envelope
/// `{ "error": { "code", "message", "details"? }, "requestId" }`.
String? apiErrorCode(Object? data) {
  if (data is Map && data['error'] is Map) {
    final code = (data['error'] as Map)['code'];
    if (code is String) return code;
  }
  return null;
}

AppException mapDioException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const AppException(code: AppException.timeout, message: 'Request timed out');
    case DioExceptionType.connectionError:
      return const AppException(code: AppException.network, message: 'No connection');
    case DioExceptionType.unknown:
      if (error.response == null) {
        return AppException(code: AppException.network, message: '${error.error ?? 'Network'}');
      }
    case DioExceptionType.badCertificate:
    case DioExceptionType.cancel:
    case DioExceptionType.badResponse:
      break;
  }
  final response = error.response;
  final data = response?.data;
  if (data is Map && data['error'] is Map) {
    final envelope = Map<String, dynamic>.from(data['error'] as Map);
    final details = envelope['details'];
    return AppException(
      code: envelope['code'] as String? ?? AppException.unknown,
      message: envelope['message'] as String? ?? '',
      statusCode: response?.statusCode,
      details: details is Map ? Map<String, dynamic>.from(details) : const {},
      requestId: data['requestId'] as String?,
    );
  }
  return AppException(
    code: AppException.badResponse,
    message: 'Unexpected response',
    statusCode: response?.statusCode,
  );
}
