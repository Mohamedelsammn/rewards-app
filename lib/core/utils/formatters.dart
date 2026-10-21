import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class Formatters {
  const Formatters._();

  /// Points use Western digits with grouping in both languages, matching the
  /// redesign's "6,000 PTS" style.
  static String points(int value) => NumberFormat.decimalPattern('en').format(value);

  static String date(BuildContext context, DateTime value) =>
      DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(value);

  static String dateTime(BuildContext context, DateTime value) =>
      DateFormat.yMMMd(Localizations.localeOf(context).languageCode).add_Hm().format(value);

  /// `mm:ss` for countdowns.
  static String countdown(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = (safe ~/ 60).toString().padLeft(2, '0');
    final rest = (safe % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }
}
