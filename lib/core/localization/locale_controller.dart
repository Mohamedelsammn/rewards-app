import 'package:flutter/material.dart';

import '../../services/secure_storage_service.dart';

const List<Locale> kSupportedLocales = [Locale('en'), Locale('ar')];

/// Persists the user's language choice and drives `MaterialApp.locale`.
/// A plain [ValueNotifier] rather than a full Cubit -- there's exactly one
/// piece of state (the current [Locale]) and one consumer (the app root),
/// so a Bloc/Cubit would be ceremony without benefit here.
///
/// Switching language does not require an app restart: [RewardsApp] listens
/// via [ValueListenableBuilder] and rebuilds `MaterialApp` (and therefore
/// every `AppLocalizations.of(context)` lookup) immediately.
class LocaleController extends ValueNotifier<Locale> {
  /// Arabic is the first-run fallback. A previously persisted language is
  /// loaded by [loadPersisted] during bootstrap and takes precedence, so an
  /// existing English selection is never overwritten on app updates.
  LocaleController(this._secureStorage) : super(const Locale('ar'));

  final SecureStorageService _secureStorage;

  Future<void> loadPersisted() async {
    final code = await _secureStorage.cachedLanguageCode;
    if (code != null && kSupportedLocales.any((l) => l.languageCode == code)) {
      value = Locale(code);
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (value == locale) return;
    value = locale;
    await _secureStorage.saveLanguageCode(locale.languageCode);
  }

  bool get isRtl => value.languageCode == 'ar';
}
