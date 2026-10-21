import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/localization/locale_controller.dart';
import 'package:rewardsapp/services/secure_storage_service.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late _MockSecureStorageService storage;

  setUp(() {
    storage = _MockSecureStorageService();
    when(() => storage.cachedLanguageCode).thenAnswer((_) async => null);
    when(() => storage.saveLanguageCode(any())).thenAnswer((_) async {});
  });

  test('fresh install defaults to Arabic regardless of the device locale', () async {
    // MaterialApp receives the explicit controller locale, so the system
    // locale cannot override this first-run fallback.
    final controller = LocaleController(storage);
    addTearDown(controller.dispose);

    expect(controller.value, const Locale('ar'));
    expect(controller.isRtl, isTrue);
    await controller.loadPersisted();
    expect(controller.value, const Locale('ar'));
  });

  test('saved English and Arabic choices override the first-run fallback', () async {
    for (final code in ['en', 'ar']) {
      when(() => storage.cachedLanguageCode).thenAnswer((_) async => code);
      final controller = LocaleController(storage);
      await controller.loadPersisted();

      expect(controller.value, Locale(code));
      expect(controller.isRtl, code == 'ar');
      controller.dispose();
    }
  });

  test('language switch persists and is restored by a new controller', () async {
    var persistedCode = 'ar';
    when(() => storage.cachedLanguageCode).thenAnswer((_) async => persistedCode);
    when(() => storage.saveLanguageCode(any())).thenAnswer((invocation) async {
      persistedCode = invocation.positionalArguments.single as String;
    });

    final firstRun = LocaleController(storage);
    await firstRun.loadPersisted();
    expect(firstRun.value, const Locale('ar'));

    await firstRun.setLocale(const Locale('en'));
    expect(firstRun.value, const Locale('en'));
    verify(() => storage.saveLanguageCode('en')).called(1);
    firstRun.dispose();

    final afterRestart = LocaleController(storage);
    await afterRestart.loadPersisted();
    expect(afterRestart.value, const Locale('en'));
    expect(afterRestart.isRtl, isFalse);
    afterRestart.dispose();
  });

  test('unsupported stored locale safely keeps Arabic fallback', () async {
    when(() => storage.cachedLanguageCode).thenAnswer((_) async => 'fr');
    final controller = LocaleController(storage);
    addTearDown(controller.dispose);

    await controller.loadPersisted();

    expect(controller.value, const Locale('ar'));
  });
}
