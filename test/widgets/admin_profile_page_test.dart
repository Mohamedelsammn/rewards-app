import 'package:flutter/material.dart';
import 'package:rewardsapp/shared/widgets/settings_section.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/di/injection.dart';
import 'package:rewardsapp/core/localization/locale_controller.dart';
import 'package:rewardsapp/features/admin_settings/presentation/admin_profile_page.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';
import 'package:rewardsapp/l10n/generated/app_localizations_ar.dart';
import 'package:rewardsapp/services/secure_storage_service.dart';
import 'package:rewardsapp/shared/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

const _adminUser = User(
  id: 'admin-1',
  appMetadata: {},
  userMetadata: {'full_name': 'Ali'},
  aud: 'authenticated',
  email: 'ali@example.com',
  createdAt: '2026-01-01T00:00:00Z',
);

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late MockAuthRepository authRepository;
  late MockSecureStorageService secureStorage;

  setUp(() async {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    authRepository = MockAuthRepository();
    secureStorage = MockSecureStorageService();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(_adminUser);
    when(() => secureStorage.cachedLanguageCode).thenAnswer((_) async => null);
    when(() => secureStorage.saveLanguageCode(any())).thenAnswer((_) async {});

    await getIt.reset();
    getIt
      ..registerSingleton<SupabaseClient>(client)
      ..registerSingleton<AuthRepository>(authRepository)
      ..registerSingleton<SecureStorageService>(secureStorage)
      ..registerSingleton<LocaleController>(LocaleController(secureStorage));
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpAdminProfile(WidgetTester tester) async {
    await tester.pumpWidget(
      // Mirrors RewardsApp's own ValueListenableBuilder<Locale> wiring in
      // main.dart, so switching the (single, real) LocaleController the
      // Language row writes to actually flips MaterialApp.locale here too --
      // otherwise the picker could "work" against the controller while the
      // rendered UI never visibly changes language.
      ValueListenableBuilder<Locale>(
        valueListenable: getIt<LocaleController>(),
        builder: (context, locale, _) => MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ar')],
          // Mirrors exactly what AdminShell provides its hosted pages -- see
          // shell_material_ancestor_test.dart for the generic version of
          // this regression guard; this one exercises the real, current
          // AdminProfilePage (including the language row added this pass).
          home: Material(type: MaterialType.transparency, child: const AdminProfilePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders without a "No Material widget found" exception', (tester) async {
    await pumpAdminProfile(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Ali'), findsOneWidget);
    // A fresh install now starts in Arabic; use the active locale's copy.
    expect(find.text(AppLocalizationsAr().settingsSignOut), findsOneWidget);
  });

  testWidgets('tapping Language opens the picker and switches to Arabic, persisting the choice', (
    tester,
  ) async {
    // Begin with the explicit English preference this test is meant to
    // switch away from. Real startup restores this value before runApp.
    await getIt<LocaleController>().setLocale(const Locale('en'));
    await pumpAdminProfile(tester);

    expect(find.widgetWithText(SettingsRow, 'Language'), findsOneWidget);
    await tester.tap(find.widgetWithText(SettingsRow, 'Language'));
    await tester.pumpAndSettle();

    expect(find.text('العربية'), findsOneWidget);

    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();

    verify(() => secureStorage.saveLanguageCode('ar')).called(1);
    // The Admin UI updates immediately -- the page's own title re-renders
    // in Arabic without needing to leave the Admin app.
    expect(find.text(AppLocalizationsAr().adminProfileTitle), findsOneWidget);
  });
}
