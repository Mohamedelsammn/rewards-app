/// The single error type that crosses from the data layer into domain and
/// presentation. [code] is the stable machine code from the API error
/// envelope (docs/FLUTTER_INTEGRATION-5.md §2), or one of the client-side
/// codes below. The UI localizes by [code]; [message] is English and only
/// meant for logs.
class AppException implements Exception {
  const AppException({
    required this.code,
    this.message = '',
    this.statusCode,
    this.details = const {},
    this.requestId,
  });

  static const network = 'NETWORK_ERROR';
  static const timeout = 'TIMEOUT';
  static const unknown = 'UNKNOWN_ERROR';
  static const badResponse = 'BAD_RESPONSE';

  /// The stored session could not be read (e.g. restored from a backup
  /// without this device's keys) and was discarded; sign-in is needed.
  static const storageReset = 'SESSION_STORAGE_RESET';

  final String code;
  final String message;
  final int? statusCode;
  final Map<String, dynamic> details;
  final String? requestId;

  bool get isConnectivity => code == network || code == timeout;

  /// `details.fields` of a `422 VALIDATION_FAILED` response, as field → code.
  Map<String, String> get fieldErrors {
    final fields = details['fields'];
    if (fields is! Map) return const {};
    return {for (final entry in fields.entries) '${entry.key}': '${entry.value}'};
  }

  /// `details.retryAfter` (seconds) on cooldown and rate-limit responses.
  int? get retryAfterSeconds {
    final value = details['retryAfter'];
    return value is num ? value.toInt() : int.tryParse('$value');
  }

  @override
  String toString() => 'AppException($code, $statusCode, $message, requestId: $requestId)';
}
