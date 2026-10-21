import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/di/injection.dart';
import 'package:rewardsapp/core/error/failure.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/settings/presentation/edit_profile_page.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';
import 'package:rewardsapp/services/secure_storage_service.dart';
import 'package:rewardsapp/shared/models/user_profile.dart';
import 'package:rewardsapp/shared/repositories/user_repository.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockUserRepository extends Mock implements UserRepository {}

/// Phase 7 (Edit Profile): the phone-editing UI never assumes a phone is
/// free -- every save routes through [UserRepository.updateProfile] (backed
/// by the server-authoritative `fn_update_user_profile`), and a
/// [PhoneAlreadyInUseFailure] response must surface a clean message without
/// touching the locally cached identity or leaving the form.
void main() {
  late MockSecureStorageService secureStorage;
  late MockUserRepository userRepository;

  setUp(() async {
    secureStorage = MockSecureStorageService();
    userRepository = MockUserRepository();

    await getIt.reset();
    getIt
      ..registerSingleton<SecureStorageService>(secureStorage)
      ..registerSingleton<UserRepository>(userRepository);

    when(() => secureStorage.cachedFullName).thenAnswer((_) async => 'Jane Doe');
    when(() => secureStorage.cachedPhone).thenAnswer((_) async => '+12025550190');
    when(() => secureStorage.cachedCountryCode).thenAnswer((_) async => 'US');
    when(
      () => secureStorage.saveIdentity(
        userId: any(named: 'userId'),
        fullName: any(named: 'fullName'),
        phone: any(named: 'phone'),
        countryCode: any(named: 'countryCode'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await getIt.reset();
  });

  /// Pushes EditProfilePage as a real route (rather than as `home:`
  /// directly) so its `Navigator.of(context).pop(true)` on success has
  /// somewhere real to pop back to.
  Future<void> pumpPushedEditProfile(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(
                  context,
                ).push<bool>(MaterialPageRoute(builder: (_) => const EditProfilePage())),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('pre-fills the form with the cached identity', (tester) async {
    await pumpPushedEditProfile(tester);

    // find.text() alone is ambiguous here (the AppBar/back-button semantics
    // can surface a second matching Text node), so read the actual
    // TextFormField controllers instead of relying on that.
    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
    expect(fields[0].controller?.text, 'Jane Doe');
    expect(fields[1].controller?.text, '2025550190');
  });

  testWidgets(
    'a duplicate phone is rejected with a clean message, the form stays open, and the '
    'local identity cache is never touched',
    (tester) async {
      when(
        () => userRepository.updateProfile(
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
          countryCode: any(named: 'countryCode'),
        ),
      ).thenAnswer((_) async => const Result.failure(PhoneAlreadyInUseFailure()));

      await pumpPushedEditProfile(tester);
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(
        find.text('This phone number is already used by another account.'),
        findsOneWidget,
      );
      expect(find.byType(EditProfilePage), findsOneWidget);
      verifyNever(
        () => secureStorage.saveIdentity(
          userId: any(named: 'userId'),
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
          countryCode: any(named: 'countryCode'),
        ),
      );
    },
  );

  testWidgets('a successful edit updates the cached identity and returns to the caller', (
    tester,
  ) async {
    when(
      () => userRepository.updateProfile(
        fullName: any(named: 'fullName'),
        phone: any(named: 'phone'),
        countryCode: any(named: 'countryCode'),
      ),
    ).thenAnswer(
      (_) async => const Result.success(
        UserProfile(
          id: 'u1',
          fullName: 'Jane Doe',
          phoneE164: '+12025550190',
          countryCode: 'US',
        ),
      ),
    );

    await pumpPushedEditProfile(tester);
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    verify(
      () => secureStorage.saveIdentity(
        userId: 'u1',
        fullName: 'Jane Doe',
        phone: '+12025550190',
        countryCode: 'US',
      ),
    ).called(1);
    expect(find.byType(EditProfilePage), findsNothing);
  });
}
