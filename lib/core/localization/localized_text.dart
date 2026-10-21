import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

/// Backend-managed text: `{ "ar": "...", "en": "..." }`. The app picks the
/// language and falls back to the other one when a translation is empty.
class LocalizedText extends Equatable {
  const LocalizedText({this.ar = '', this.en = ''});

  const LocalizedText.same(String value) : ar = value, en = value;

  factory LocalizedText.fromJson(Object? json) {
    if (json is Map) {
      return LocalizedText(ar: '${json['ar'] ?? ''}', en: '${json['en'] ?? ''}');
    }
    if (json is String) return LocalizedText.same(json);
    return const LocalizedText();
  }

  final String ar;
  final String en;

  bool get isEmpty => ar.trim().isEmpty && en.trim().isEmpty;

  String resolve(String languageCode) {
    final primary = languageCode == 'ar' ? ar : en;
    if (primary.trim().isNotEmpty) return primary;
    return languageCode == 'ar' ? en : ar;
  }

  String of(BuildContext context) => resolve(Localizations.localeOf(context).languageCode);

  /// English text, or Arabic when English is empty. Used for matching
  /// bundled artwork by keyword.
  String get matchText => (en.trim().isNotEmpty ? en : ar).toLowerCase();

  @override
  List<Object?> get props => [ar, en];
}
