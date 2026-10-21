import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import '../security/secure_token_storage.dart';

const List<Locale> kSupportedLocales = [Locale('en'), Locale('ar')];

/// Holds and persists the app language. A previously saved preference
/// (including one saved by earlier app versions under the same key) wins;
/// a first launch follows the device language (Arabic or English), since
/// the language picker is only reachable after signing in.
class LocaleController extends ValueNotifier<Locale> {
  LocaleController(this._storage) : super(const Locale('en'));

  final SecureTokenStorage _storage;

  Future<void> loadPersisted({Locale? deviceLocale}) async {
    final code = await _storage.languageCode;
    if (code != null && kSupportedLocales.any((locale) => locale.languageCode == code)) {
      value = Locale(code);
      return;
    }
    final device = deviceLocale ?? PlatformDispatcher.instance.locale;
    value = device.languageCode == 'ar' ? const Locale('ar') : const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    if (value == locale) return;
    value = locale;
    await _storage.saveLanguageCode(locale.languageCode);
  }

  String get languageCode => value.languageCode;

  bool get isRtl => value.languageCode == 'ar';
}
