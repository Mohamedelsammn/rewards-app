import 'package:flutter/foundation.dart';

import '../error/app_exception.dart';

/// Rewarded-ad diagnostics: session lifecycle, HTTP results, AdMob load and
/// show events and timings, to trace the Flutter → AdMob → backend flow.
///
/// Off in store builds; on in debug builds or with
/// `--dart-define=AD_DIAGNOSTICS=true`. Never logs tokens or user data.
const adDiagnosticsEnabled = kDebugMode || bool.fromEnvironment('AD_DIAGNOSTICS');

void adLog(String message) {
  if (adDiagnosticsEnabled) debugPrint('[ads] $message');
}

/// Ad load and show failures, logged in every build (to logcat, never in
/// the UI): SDK error code, domain and message only, no user data.
void adWarn(String message) => debugPrint('[ads] $message');

String adDescribeError(Object error) => error is AppException
    ? 'code=${error.code} http=${error.statusCode} requestId=${error.requestId}'
    : error.runtimeType.toString();
