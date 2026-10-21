import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:rewardsapp/core/config/app_config.dart';
import 'package:rewardsapp/core/di/injection.dart';
import 'package:rewardsapp/features/admin_auth/presentation/admin_auth_page.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';
import 'package:rewardsapp/shared/repositories/auth_repository.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class _FakeUrlLauncher extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  String? lastLaunchedUrl;
  bool launchResult = true;

  @override
  get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    return launchResult;
  }
}

/// Part 1: Admin Sign Up → WhatsApp contact section. Replaces the old
/// phone-call requirement -- someone without an Admin Access Code must be
/// able to reach the admin over a plain `wa.me` deep link (never a paid
/// WhatsApp Business API), with the number sourced from exactly one
/// centralized constant ([AppConfig.adminContactPhone]).
void main() {
  late MockAuthRepository authRepository;
  late _FakeUrlLauncher fakeLauncher;

  setUp(() async {
    authRepository = MockAuthRepository();
    fakeLauncher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = fakeLauncher;

    await getIt.reset();
    getIt.registerSingleton<AuthRepository>(authRepository);
  });

  tearDown(() async => getIt.reset());

  Future<void> pumpAdminAuth(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: const AdminAuthPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('is not shown in Sign In mode', (tester) async {
    await pumpAdminAuth(tester);

    expect(find.text("Don't have an Admin Access Code?"), findsNothing);
  });

  testWidgets(
    'appears in Sign Up mode with the centralized contact number, and tapping it opens '
    'WhatsApp with the correct number and English message',
    (tester) async {
      await pumpAdminAuth(tester);

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text("Don't have an Admin Access Code?"), findsOneWidget);
      expect(find.text('Contact us on WhatsApp to request access.'), findsOneWidget);
      expect(find.text(AppConfig.adminContactPhone), findsOneWidget);

      await tester.ensureVisible(find.text(AppConfig.adminContactPhone));
      await tester.tap(find.text(AppConfig.adminContactPhone));
      await tester.pumpAndSettle();

      final launchedUri = Uri.parse(fakeLauncher.lastLaunchedUrl!);
      expect(launchedUri.host, 'wa.me');
      expect(launchedUri.path, '/201203433339');
      expect(
        launchedUri.queryParameters['text'],
        'Hello, I would like to join your giveaways. I need an Admin Access Code to '
        'create an admin account.',
      );
    },
  );

  testWidgets('pre-fills the Arabic message when the app language is Arabic', (tester) async {
    await pumpAdminAuth(tester, locale: const Locale('ar'));

    await tester.tap(find.text('إنشاء حساب'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(AppConfig.adminContactPhone));
    await tester.tap(find.text(AppConfig.adminContactPhone));
    await tester.pumpAndSettle();

    final launchedUri = Uri.parse(fakeLauncher.lastLaunchedUrl!);
    expect(
      launchedUri.queryParameters['text'],
      'مرحباً، أريد الانضمام إلى المسابقات الخاصة بكم وأحتاج إلى كود دخول المسؤول لإنشاء حساب '
      'Admin.',
    );
  });

  testWidgets('shows a clean error instead of crashing when WhatsApp cannot be opened', (
    tester,
  ) async {
    fakeLauncher.launchResult = false;
    await pumpAdminAuth(tester);

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(AppConfig.adminContactPhone));
    await tester.tap(find.text(AppConfig.adminContactPhone));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Could not open WhatsApp. Please try again.'), findsOneWidget);
  });
}
