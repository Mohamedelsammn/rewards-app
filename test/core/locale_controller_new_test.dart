import 'dart:ui';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/core/localization/locale_controller.dart';
import 'package:rewardsapp/core/security/secure_token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LocaleController> load(Map<String, String> stored, Locale device) async {
    FlutterSecureStorage.setMockInitialValues(Map.of(stored));
    final controller = LocaleController(SecureTokenStorage());
    await controller.loadPersisted(deviceLocale: device);
    return controller;
  }

  test('first launch follows the device language', () async {
    expect((await load({}, const Locale('ar', 'EG'))).value, const Locale('ar'));
    expect((await load({}, const Locale('fr'))).value, const Locale('en'));
  });

  test('a saved choice wins over the device language', () async {
    final controller = await load({'cached_language_code': 'en'}, const Locale('ar'));
    expect(controller.value, const Locale('en'));
    await controller.setLocale(const Locale('ar'));
    expect((await load({'cached_language_code': 'ar'}, const Locale('en'))).isRtl, isTrue);
  });
}
