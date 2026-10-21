import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/di/injection.dart';
import 'package:rewardsapp/core/localization/locale_controller.dart';
import 'package:rewardsapp/core/theme/app_theme.dart';
import 'package:rewardsapp/features/legal/presentation/privacy_policy_page.dart';
import 'package:rewardsapp/features/settings/presentation/settings_page.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';
import 'package:rewardsapp/services/notification_service.dart';
import 'package:rewardsapp/services/secure_storage_service.dart';
import 'package:rewardsapp/shared/widgets/settings_section.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockNotificationService extends Mock implements NotificationService {}

/// Covers the Phase 6 redesign: a Guest vs. registered profile header
/// sourced from the existing locally cached identity (no new user record,
/// no hardcoded data), grouped settings sections, and a large primary-
/// styled Sign Out control instead of a plain row.
void main() {
  late MockSecureStorageService secureStorage;
  late MockNotificationService notificationService;
  late StreamController<void> identityChanged;

  setUp(() async {
    secureStorage = MockSecureStorageService();
    notificationService = MockNotificationService();
    identityChanged = StreamController<void>.broadcast();
    addTearDown(identityChanged.close);

    when(() => secureStorage.identityChanged).thenAnswer((_) => identityChanged.stream);
    when(() => secureStorage.cachedCountryCode).thenAnswer((_) async => null);

    await getIt.reset();
    getIt
      ..registerSingleton<SecureStorageService>(secureStorage)
      ..registerSingleton<NotificationService>(notificationService);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpSettings(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        theme: AppTheme.light,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('ar')],
        home: const Scaffold(
          body: Material(type: MaterialType.transparency, child: SettingsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 360.0, 393.0, 430.0, 600.0]) {
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      testWidgets('compact profile and settings rows fit $width ${locale.languageCode}', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        when(
          () => secureStorage.cachedFullName,
        ).thenAnswer((_) async => 'اسم طويل للمشارك في المسابقات Rewards participant');
        when(() => secureStorage.cachedPhone).thenAnswer((_) async => '+201012345678');
        await pumpSettings(tester, locale: locale);
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          Directionality.of(tester.element(find.byType(SettingsPage))),
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
      });
    }
  }

  testWidgets('About, policy, terms and language retain their navigation', (tester) async {
    when(() => secureStorage.cachedFullName).thenAnswer((_) async => null);
    when(() => secureStorage.cachedPhone).thenAnswer((_) async => null);
    when(() => secureStorage.saveLanguageCode(any())).thenAnswer((_) async {});
    final locale = LocaleController(secureStorage);
    getIt.registerSingleton<LocaleController>(locale);
    addTearDown(locale.dispose);
    // This widget test deliberately starts in English so that choosing
    // Arabic exercises a real locale change (fresh installs now default to
    // Arabic).
    await locale.setLocale(const Locale('en'));
    await pumpSettings(tester);
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    for (final label in ['Privacy Policy', 'Terms & Conditions']) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(
        find.byType(label == 'Privacy Policy' ? PrivacyPolicyPage : TermsConditionsPage),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Language'));
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();
    expect(locale.value, const Locale('ar'));
    verify(() => secureStorage.saveLanguageCode('ar')).called(1);
  });

  testWidgets('a device with no cached identity shows the Guest profile state', (tester) async {
    when(() => secureStorage.cachedFullName).thenAnswer((_) async => null);
    when(() => secureStorage.cachedPhone).thenAnswer((_) async => null);

    await pumpSettings(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Guest'), findsOneWidget);
  });

  testWidgets('a device with a cached identity shows the registered user\'s name and phone -- '
      'sourced from the existing local cache, not hardcoded', (tester) async {
    when(() => secureStorage.cachedFullName).thenAnswer((_) async => 'Jane Doe');
    when(() => secureStorage.cachedPhone).thenAnswer((_) async => '+12025550190');

    await pumpSettings(tester);

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('+12025550190'), findsOneWidget);
    expect(find.text('Guest'), findsNothing);
  });

  testWidgets('a registered profile also shows its cached region/country', (tester) async {
    when(() => secureStorage.cachedFullName).thenAnswer((_) async => 'Mohamed');
    when(() => secureStorage.cachedPhone).thenAnswer((_) async => '+201012345678');
    when(() => secureStorage.cachedCountryCode).thenAnswer((_) async => 'EG');

    await pumpSettings(tester);

    expect(find.textContaining('Egypt'), findsOneWidget);
  });

  testWidgets(
    'long username is kept to one ellipsized line and missing profile fields are hidden',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const longName = 'A very long participant name that should never overflow the profile card';
      when(() => secureStorage.cachedFullName).thenAnswer((_) async => longName);
      when(() => secureStorage.cachedPhone).thenAnswer((_) async => '   ');
      when(() => secureStorage.cachedCountryCode).thenAnswer((_) async => null);

      await pumpSettings(tester);

      final username = tester.widget<Text>(find.text(longName));
      expect(username.maxLines, 1);
      expect(username.overflow, TextOverflow.ellipsis);
      expect(find.byKey(const ValueKey('settings-profile-phone')), findsNothing);
      expect(find.textContaining('null'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Arabic profile mirrors the avatar and keeps the phone LTR and formatted', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(() => secureStorage.cachedFullName).thenAnswer((_) async => 'محمد');
    when(() => secureStorage.cachedPhone).thenAnswer((_) async => '+201012345678');
    when(() => secureStorage.cachedCountryCode).thenAnswer((_) async => 'EG');

    await pumpSettings(tester, locale: const Locale('ar'));

    expect(find.text('+20 10 1234 5678'), findsOneWidget);
    expect(find.text('🇪🇬'), findsOneWidget);
    expect(find.text('Egypt'), findsOneWidget);
    final phoneDirection = tester.widget<Directionality>(
      find.byKey(const ValueKey('settings-profile-phone-direction')),
    );
    expect(phoneDirection.textDirection, TextDirection.ltr);
    expect(
      tester.getCenter(find.byType(ProfileAvatar)).dx,
      greaterThan(tester.getCenter(find.text('محمد')).dx),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a registration completed elsewhere (e.g. Giveaway Details\' participation flow) while '
    'this already-mounted Settings screen is alive is reflected immediately -- no navigation '
    'away and back, no app restart -- covers the "profile only appears after a refresh" fix',
    (tester) async {
      when(() => secureStorage.cachedFullName).thenAnswer((_) async => null);
      when(() => secureStorage.cachedPhone).thenAnswer((_) async => null);

      await pumpSettings(tester);
      expect(find.text('Guest'), findsOneWidget);

      // The registration flow saved a new identity on a completely
      // different screen; only the cached-read stubs change here, exactly
      // like the real SecureStorageService would return after
      // ParticipationCubit.submitRegistration -> saveIdentity() persists it.
      when(() => secureStorage.cachedFullName).thenAnswer((_) async => 'Mohamed');
      when(() => secureStorage.cachedPhone).thenAnswer((_) async => '+201012345678');
      when(() => secureStorage.cachedCountryCode).thenAnswer((_) async => 'EG');
      identityChanged.add(null);
      await tester.pumpAndSettle();

      expect(find.text('Mohamed'), findsOneWidget);
      expect(find.text('+20 10 1234 5678'), findsOneWidget);
      expect(find.text('Guest'), findsNothing);
    },
  );

  testWidgets('Sign Out is a large primary-styled button, and grouped sections are present', (
    tester,
  ) async {
    when(() => secureStorage.cachedFullName).thenAnswer((_) async => null);
    when(() => secureStorage.cachedPhone).thenAnswer((_) async => null);

    await pumpSettings(tester);

    // Not a plain ListTile row -- the label sits inside the same
    // gradient/pill button style used for Generate Number/Sign In.
    expect(find.widgetWithText(ListTile, 'Sign Out'), findsNothing);
    expect(find.text('Sign Out'), findsOneWidget);

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms & Conditions'), findsOneWidget);
  });
}
