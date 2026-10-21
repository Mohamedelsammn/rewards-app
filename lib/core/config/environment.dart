import 'package:flutter/foundation.dart';

/// Build-time configuration. Every value is overridable with `--dart-define`:
///
/// ```
/// flutter run --dart-define=DATA_MODE=api \
///   --dart-define=API_BASE_URL=https://rewards-api.creativevpnapp.com/api/v1
/// ```
///
/// The API base URL is the only server address in the app. It must end with
/// `/api/v1` and have no trailing slash (see docs/FLUTTER_INTEGRATION-5.md §1).
class Environment {
  const Environment._();

  /// Only the production REST API is supported. The former local demo and
  /// the legacy Supabase integration were removed with the redesign refactor.
  static const dataMode = String.fromEnvironment('DATA_MODE', defaultValue: 'api');

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://rewards-api.creativevpnapp.com/api/v1',
  );

  /// Why the app cannot start, or `null` when the configuration is usable.
  static EnvironmentIssue? get issue =>
      validate(dataMode: dataMode, apiBaseUrl: apiBaseUrl, releaseMode: kReleaseMode);

  @visibleForTesting
  static EnvironmentIssue? validate({
    required String dataMode,
    required String apiBaseUrl,
    required bool releaseMode,
  }) {
    if (dataMode != 'api') return EnvironmentIssue.unsupportedDataMode;
    final uri = Uri.tryParse(apiBaseUrl);
    if (apiBaseUrl.isEmpty || uri == null || !uri.hasAuthority) {
      return EnvironmentIssue.apiNotConfigured;
    }
    // Release builds must never talk to the backend over plain HTTP.
    if (releaseMode && uri.scheme != 'https') return EnvironmentIssue.insecureApiUrl;
    return null;
  }
}

enum EnvironmentIssue { unsupportedDataMode, apiNotConfigured, insecureApiUrl }
