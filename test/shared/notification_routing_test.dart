import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/di/injection.dart';
import 'package:rewardsapp/core/error/failure.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/winner_celebration/presentation/winner_celebration_page.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';
import 'package:rewardsapp/services/secure_storage_service.dart';
import 'package:rewardsapp/shared/models/winner.dart';
import 'package:rewardsapp/shared/repositories/winner_repository.dart';
import 'package:rewardsapp/shared/utils/notification_routing.dart';

class MockWinnerRepository extends Mock implements WinnerRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

final _winner = Winner(
  id: 'w1',
  giveawayId: 'g1',
  participationId: 'p1',
  rank: 1,
  selectedAt: DateTime(2026, 1, 1),
  celebrationAcknowledgedAt: null,
);

/// Covers the same-device Admin -> User winner-celebration bug: Admin selects
/// a User as winner, signs out, and the User re-enters right after. Right at
/// that moment the client's auth attachment can still be settling, so a
/// pending-winner lookup can transiently fail -- and previously, that single
/// failure permanently lost the one chance to show the celebration (see
/// notification_routing.dart's checkForPendingWinnerAndCelebrate and
/// UserIdentityService's session-attachment fix for the other half of this).
void main() {
  late MockWinnerRepository winnerRepository;
  late MockSecureStorageService secureStorage;

  setUp(() async {
    winnerRepository = MockWinnerRepository();
    secureStorage = MockSecureStorageService();
    await getIt.reset();
    getIt
      ..registerSingleton<WinnerRepository>(winnerRepository)
      ..registerSingleton<SecureStorageService>(secureStorage);
  });

  tearDown(() async => getIt.reset());

  Future<BuildContext> pumpHarness(WidgetTester tester) async {
    late BuildContext captured;
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
          builder: (context) {
            captured = context;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );
    return captured;
  }

  group('checkForPendingWinnerAndCelebrate -- transient-failure retry', () {
    testWidgets('a lookup that fails once (e.g. the auth attachment still settling right after a '
        'session switch) is retried, and a winner found on retry still triggers the '
        'celebration', (tester) async {
      when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-123');
      var callCount = 0;
      when(() => winnerRepository.getMyPendingWinner('user-123')).thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? const Result.failure(NetworkFailure()) : Result.success(_winner);
      });

      final context = await pumpHarness(tester);
      unawaited(checkForPendingWinnerAndCelebrate(context));
      // tester.pump(duration) -- not a real Future.delayed -- is what
      // actually elapses the fake clock this test's Timers run on, so
      // this is what advances the function's own retry backoff.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump();

      expect(callCount, 2);
      expect(find.byType(WinnerCelebrationPage), findsOneWidget);
    });

    testWidgets('a lookup that fails twice in a row gives up cleanly -- no celebration, no crash', (
      tester,
    ) async {
      when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-123');
      when(
        () => winnerRepository.getMyPendingWinner('user-123'),
      ).thenAnswer((_) async => const Result.failure(NetworkFailure()));

      final context = await pumpHarness(tester);
      unawaited(checkForPendingWinnerAndCelebrate(context));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      verify(() => winnerRepository.getMyPendingWinner('user-123')).called(2);
      expect(find.byType(WinnerCelebrationPage), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a successful lookup that legitimately finds no winner is never retried', (
      tester,
    ) async {
      when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-123');
      when(
        () => winnerRepository.getMyPendingWinner('user-123'),
      ).thenAnswer((_) async => const Result.success(null));

      final context = await pumpHarness(tester);
      await checkForPendingWinnerAndCelebrate(context);
      await tester.pump();

      verify(() => winnerRepository.getMyPendingWinner('user-123')).called(1);
      expect(find.byType(WinnerCelebrationPage), findsNothing);
    });

    testWidgets('a winner found on the very first try (the common case) is never retried', (
      tester,
    ) async {
      when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-123');
      when(
        () => winnerRepository.getMyPendingWinner('user-123'),
      ).thenAnswer((_) async => Result.success(_winner));

      final context = await pumpHarness(tester);
      unawaited(checkForPendingWinnerAndCelebrate(context));
      await tester.pump();
      await tester.pump();

      verify(() => winnerRepository.getMyPendingWinner('user-123')).called(1);
      expect(find.byType(WinnerCelebrationPage), findsOneWidget);
    });
  });
}
