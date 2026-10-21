import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/error/failure.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/admin_analysis/presentation/bloc/admin_analysis_cubit.dart';
import 'package:rewardsapp/features/admin_analysis/presentation/bloc/admin_analysis_state.dart';
import 'package:rewardsapp/shared/models/giveaway.dart';
import 'package:rewardsapp/shared/models/winner.dart';
import 'package:rewardsapp/shared/repositories/giveaway_repository.dart';
import 'package:rewardsapp/shared/repositories/winner_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGiveawayRepository extends Mock implements GiveawayRepository {}

class MockWinnerRepository extends Mock implements WinnerRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class _FakeRealtimeChannel extends Fake implements RealtimeChannel {}

const _adminUser = User(
  id: 'admin-1',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

Giveaway _giveaway(String id, GiveawayStatus status, int participants) => Giveaway(
  id: id,
  title: 'Prize $id',
  organizerName: 'Org',
  prizeDescription: 'Prize',
  descriptionRules: 'Rules',
  imageUrl: null,
  startDate: DateTime(2026, 1, 1),
  endDate: DateTime(2026, 1, 10),
  endTime: '18:00',
  status: status,
  numberDigitWidth: 4,
  maxParticipants: null,
  participantCount: participants,
);

/// Covers the "Admin Analysis tab doesn't reflect a just-created giveaway"
/// fix -- see docs/fixes/state-sync-and-session-restoration.md, Bug 2.
void main() {
  late MockGiveawayRepository giveawayRepository;
  late MockWinnerRepository winnerRepository;
  late MockSupabaseClient client;
  late MockGoTrueClient auth;

  setUp(() {
    giveawayRepository = MockGiveawayRepository();
    winnerRepository = MockWinnerRepository();
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(_adminUser);
    when(() => giveawayRepository.giveawayCreated).thenAnswer((_) => const Stream.empty());
    when(() => winnerRepository.winnerSelected).thenAnswer((_) => const Stream.empty());
  });

  AdminAnalysisCubit buildCubit() =>
      AdminAnalysisCubit(giveawayRepository, client, winnerRepository);

  group('AdminAnalysisCubit', () {
    blocTest<AdminAnalysisCubit, AdminAnalysisState>(
      'emits empty when the admin owns no giveaways',
      build: buildCubit,
      setUp: () => when(
        () => giveawayRepository.getMyAdminGiveaways(),
      ).thenAnswer((_) async => const Result.success([])),
      act: (cubit) => cubit.load(),
      expect: () => [
        const AdminAnalysisState(status: AdminAnalysisStatus.loading),
        const AdminAnalysisState(status: AdminAnalysisStatus.empty),
      ],
    );

    blocTest<AdminAnalysisCubit, AdminAnalysisState>(
      'aggregates active/finished counts and total participants across every owned giveaway',
      build: buildCubit,
      setUp: () => when(() => giveawayRepository.getMyAdminGiveaways()).thenAnswer(
        (_) async => Result.success([
          _giveaway('g1', GiveawayStatus.active, 3),
          _giveaway('g2', GiveawayStatus.ended, 5),
        ]),
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        const AdminAnalysisState(status: AdminAnalysisStatus.loading),
        AdminAnalysisState(
          status: AdminAnalysisStatus.loaded,
          totalGiveaways: 2,
          activeCount: 1,
          finishedCount: 1,
          totalParticipants: 8,
          // The participations-trend query isn't stubbed for this test (it's
          // non-fatal by design -- see the cubit's own try/catch) and always
          // starts pre-filled with 7 zero buckets before that query runs.
          dailyGrowth: List<int>.filled(7, 0),
        ),
      ],
    );

    blocTest<AdminAnalysisCubit, AdminAnalysisState>(
      'emits an error state when the repository fails',
      build: buildCubit,
      setUp: () => when(
        () => giveawayRepository.getMyAdminGiveaways(),
      ).thenAnswer((_) async => const Result.failure(NetworkFailure('offline'))),
      act: (cubit) => cubit.load(),
      expect: () => [
        const AdminAnalysisState(status: AdminAnalysisStatus.loading),
        const AdminAnalysisState(
          status: AdminAnalysisStatus.error,
          failure: NetworkFailure('offline'),
        ),
      ],
    );
  });

  group('AdminAnalysisCubit local create/winner signals', () {
    test(
      'reloads immediately the moment THIS admin session confirms creating a giveaway '
      '(the exact bug this fix targets)',
      () async {
        final giveawayCreated = StreamController<Giveaway>.broadcast();
        addTearDown(giveawayCreated.close);
        when(() => giveawayRepository.giveawayCreated).thenAnswer((_) => giveawayCreated.stream);
        when(
          () => giveawayRepository.getMyAdminGiveaways(),
        ).thenAnswer((_) async => const Result.success([]));

        final cubit = AdminAnalysisCubit(giveawayRepository, client, winnerRepository);
        giveawayCreated.add(_giveaway('g1', GiveawayStatus.active, 0));
        await Future<void>.delayed(Duration.zero);

        verify(() => giveawayRepository.getMyAdminGiveaways()).called(1);
        await cubit.close();
      },
    );

    test('reloads immediately the moment THIS admin session confirms selecting a winner', () async {
      final winnerSelected = StreamController<Winner>.broadcast();
      addTearDown(winnerSelected.close);
      when(() => winnerRepository.winnerSelected).thenAnswer((_) => winnerSelected.stream);
      when(
        () => giveawayRepository.getMyAdminGiveaways(),
      ).thenAnswer((_) async => const Result.success([]));

      final cubit = AdminAnalysisCubit(giveawayRepository, client, winnerRepository);
      winnerSelected.add(
        Winner(
          id: 'w1',
          giveawayId: 'g1',
          participationId: 'p1',
          rank: 1,
          selectedAt: DateTime(2026, 1, 1),
          celebrationAcknowledgedAt: null,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      verify(() => giveawayRepository.getMyAdminGiveaways()).called(1);
      await cubit.close();
    });
  });

  group('AdminAnalysisCubit realtime lifecycle', () {
    setUpAll(() {
      registerFallbackValue(PostgresChangeEvent.all);
      registerFallbackValue(_FakeRealtimeChannel());
    });

    void stubChannel(MockRealtimeChannel channel) {
      when(() => client.channel(any())).thenReturn(channel);
      when(
        () => channel.onPostgresChanges(
          event: any(named: 'event'),
          schema: any(named: 'schema'),
          table: any(named: 'table'),
          filter: any(named: 'filter'),
          callback: any(named: 'callback'),
        ),
      ).thenReturn(channel);
      when(() => channel.subscribe()).thenReturn(channel);
      when(() => client.removeChannel(any())).thenAnswer((_) async => 'ok');
    }

    test('opens exactly one channel scoped to this admin, and a second call is a no-op', () {
      stubChannel(MockRealtimeChannel());

      final cubit = AdminAnalysisCubit(giveawayRepository, client, winnerRepository);
      cubit.subscribeToRealtime();
      cubit.subscribeToRealtime();

      verify(() => client.channel('admin-analysis-giveaways-admin-1')).called(1);
    });

    test('never subscribes when there is no authenticated admin', () {
      when(() => auth.currentUser).thenReturn(null);

      final cubit = AdminAnalysisCubit(giveawayRepository, client, winnerRepository);
      cubit.subscribeToRealtime();

      verifyNever(() => client.channel(any()));
    });

    test('close() removes the subscribed channel exactly once', () async {
      stubChannel(MockRealtimeChannel());

      final cubit = AdminAnalysisCubit(giveawayRepository, client, winnerRepository);
      cubit.subscribeToRealtime();
      await cubit.close();

      verify(() => client.removeChannel(any())).called(1);
    });

    test('close() without ever subscribing does not throw', () async {
      final cubit = AdminAnalysisCubit(giveawayRepository, client, winnerRepository);
      await cubit.close();
      verifyNever(() => client.removeChannel(any()));
    });
  });
}
