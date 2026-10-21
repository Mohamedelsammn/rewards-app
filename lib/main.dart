import 'package:flutter/widgets.dart';

import 'app/bootstrap.dart';
import 'app/startup/startup_pages.dart';
import 'core/config/environment.dart';

/// Entry point. Configure with `--dart-define=DATA_MODE=api` and
/// `--dart-define=API_BASE_URL=...` (see [Environment]).
Future<void> main() async {
  final issue = Environment.issue;
  if (issue != null) {
    runApp(ServiceUnavailableApp(issue: issue));
    return;
  }
  await bootstrap();
}
