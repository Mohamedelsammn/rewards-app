import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/error/failure.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/admin_dashboard/presentation/bloc/admin_dashboard_cubit.dart';
import 'package:rewardsapp/features/admin_dashboard/presentation/bloc/admin_dashboard_state.dart';
import 'package:rewardsapp/shared/models/giveaway.dart';
import 'package:rewardsapp/shared/repositories/giveaway_repository.dart';
import 'package:rewardsapp/shared/models/winner.dart';
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

Giveaway _giveaway(String id, GiveawayStatus status, int participants) {
  final clock = DateTime.now().toUtc();
  final now = DateTime.utc(clock.year, clock.month, clock.day);
  final startsAt = switch (status) {
    GiveawayStatus.scheduled => now.add(const Duration(days: 2)),
    GiveawayStatus.ended => now.subtract(const Duration(days: 10)),
    _ => now.subtract(const Duration(days: 1)),
  };
  final endsAt = switch (status) {
    GiveawayStatus.ended => now.subtract(const Duration(days: 1)),
    _ => now.add(const Duration(days: 5)),
  };
  return Giveaway(
    id: id,
    title: 'Prize $id',
    organizerName: 'Org',
    prizeDescription: 'Prize',
    descriptionRules: 'Rules',
    imageUrl: null,
    startDate: startsAt,
    endDate: endsAt,
    endTime: '18:00',
    status: status,
    numberDigitWidth: 4,
    maxParticipants: null,
    participantCount: participants,
    startsAtUtc: startsAt,
    endsAtUtc: endsAt,
  );
}

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
    when(() => giveawayRepository.giveawayCreated).thenAnswer((_) => const Stream.empty());
    when(() => winnerRepository.winnerSelected).thenAnswer((_) => const Stream.empty());
  });

  AdminDashboardCubit buildCubit() =>
      AdminDashboardCubit(giveawayRepository, client, winnerRepository);

  group('AdminDashboardCubit', () {
    blocTest<AdminDashboardCubit, AdminDashboardState>(
      'keeps a future scheduled giveaway visible in the upcoming admin group',
      build: buildCubit,
      setUp: () {
        when(() => auth.currentUser).thenReturn(null);
        final start = DateTime.now().add(const Duration(days: 2));
        final scheduled = Giveaway(
          id: 'scheduled',
          title: 'Future prize',
          organizerName: 'Org',
          prizeDescription: '',
          descriptionRules: '',
          imageUrl: null,
          startDate: start,
          endDate: start.add(const Duration(days: 5)),
          endTime: '18:00',
          status: GiveawayStatus.scheduled,
          numberDigitWidth: 4,
          maxParticipants: null,
          participantCount: 0,
          startsAtUtc: start.toUtc(),
          endsAtUtc: start.add(const Duration(days: 5)).toUtc(),
        );
        when(
          () => giveawayRepository.getMyAdminGiveaways(),
        ).thenAnswer((_) async => Result.success([scheduled]));
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const AdminDashboardState(status: AdminDashboardStatus.loading),
        isA<AdminDashboardState>()
            .having((state) => state.status, 'status', AdminDashboardStatus.loaded)
            .having((state) => state.upcomingCampaigns.single.id, 'upcoming id', 'scheduled')
            .having((state) => state.activeCount, 'active count', 0),
      ],
    );

    blocTest<AdminDashboardCubit, AdminDashboardState>(
      'loads via getMyAdminGiveaways (never the public getGiveaways) and lists every active campaign',
      build: buildCubit,
      setUp: () {
        when(() => auth.currentUser).thenReturn(null);
        when(() => giveawayRepository.getMyAdminGiveaways()).thenAnswer(
          (_) async => Result.success([
            _giveaway('g1', GiveawayStatus.active, 3),
            _giveaway('g2', GiveawayStatus.active, 5),
            _giveaway('g3', GiveawayStatus.ended, 10),
          ]),
        );
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const AdminDashboardState(status: AdminDashboardStatus.loading),
        AdminDashboardState(
          status: AdminDashboardStatus.loaded,
          activeCount: 2,
          finishedCount: 1,
          totalParticipants: 18,
          winnersSelectedCount: 0,
          activeCampaigns: [
            _giveaway('g1', GiveawayStatus.active, 3),
            _giveaway('g2', GiveawayStatus.active, 5),
          ],
          endedCampaigns: [_giveaway('g3', GiveawayStatus.ended, 10)],
        ),
      ],
      verify: (_) {
        verify(() => giveawayRepository.getMyAdminGiveaways()).called(1);
        verifyNever(
          () => giveawayRepository.getGiveaways(forceRefresh: any(named: 'forceRefresh')),
        );
      },
    );

    blocTest<AdminDashboardCubit, AdminDashboardState>(
      'emits an error state and never touches activeCampaigns when the repository fails',
      build: buildCubit,
      setUp: () {
        when(() => auth.currentUser).thenReturn(_adminUser);
        when(
          () => giveawayRepository.getMyAdminGiveaways(),
        ).thenAnswer((_) async => const Result.failure(NetworkFailure('offline')));
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const AdminDashboardState(status: AdminDashboardStatus.loading),
        const AdminDashboardState(
          status: AdminDashboardStatus.error,
          failure: NetworkFailure('offline'),
        ),
      ],
    );

    blocTest<AdminDashboardCubit, AdminDashboardState>(
      'degrades winnersSelectedCount to 0 instead of crashing when the winners lookup fails',
      build: buildCubit,
      setUp: () {
        when(() => auth.currentUser).thenReturn(_adminUser);
        when(
          () => giveawayRepository.getMyAdminGiveaways(),
        ).thenAnswer((_) async => const Result.success([]));
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const AdminDashboardState(status: AdminDashboardStatus.loading),
        const AdminDashboardState(status: AdminDashboardStatus.loaded, winnersSelectedCount: 0),
      ],
    );

    blocTest<AdminDashboardCubit, AdminDashboardState>(
      'an ended giveaway stays reachable in endedCampaigns -- it must never simply disappear '
      'once a winner is selected',
      build: buildCubit,
      setUp: () {
        when(() => auth.currentUser).thenReturn(_adminUser);
        when(
          () => giveawayRepository.getMyAdminGiveaways(),
        ).thenAnswer((_) async => Result.success([_giveaway('g1', GiveawayStatus.ended, 7)]));
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const AdminDashboardState(status: AdminDashboardStatus.loading),
        AdminDashboardState(
          status: AdminDashboardStatus.loaded,
          activeCount: 0,
          finishedCount: 1,
          totalParticipants: 7,
          activeCampaigns: const [],
          endedCampaigns: [_giveaway('g1', GiveawayStatus.ended, 7)],
        ),
      ],
    );
  });

  group('AdminDashboardCubit local create/winner signals', () {
    test('reloads immediately the moment THIS admin session confirms creating a giveaway '
        '(no realtime round trip needed)', () async {
      final giveawayCreated = StreamController<Giveaway>.broadcast();
      addTearDown(giveawayCreated.close);
      when(() => giveawayRepository.giveawayCreated).thenAnswer((_) => giveawayCreated.stream);
      when(() => auth.currentUser).thenReturn(_adminUser);
      when(
        () => giveawayRepository.getMyAdminGiveaways(),
      ).thenAnswer((_) async => const Result.success([]));

      final cubit = AdminDashboardCubit(giveawayRepository, client, winnerRepository);
      giveawayCreated.add(_giveaway('g1', GiveawayStatus.active, 0));
      await Future<void>.delayed(Duration.zero);

      verify(() => giveawayRepository.getMyAdminGiveaways()).called(1);
      await cubit.close();
    });

    test('reloads immediately the moment THIS admin session confirms selecting a winner', () async {
      final winnerSelected = StreamController<Winner>.broadcast();
      addTearDown(winnerSelected.close);
      when(() => winnerRepository.winnerSelected).thenAnswer((_) => winnerSelected.stream);
      when(() => auth.currentUser).thenReturn(_adminUser);
      when(
        () => giveawayRepository.getMyAdminGiveaways(),
      ).thenAnswer((_) async => const Result.success([]));

      final cubit = AdminDashboardCubit(giveawayRepository, client, winnerRepository);
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

  group('AdminDashboardCubit realtime lifecycle', () {
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
      when(() => auth.currentUser).thenReturn(_adminUser);
      stubChannel(MockRealtimeChannel());

      final cubit = AdminDashboardCubit(giveawayRepository, client, winnerRepository);
      cubit.subscribeToRealtime();
      cubit.subscribeToRealtime();

      verify(() => client.channel('admin-dashboard-giveaways-admin-1')).called(1);
    });

    test('never subscribes when there is no authenticated admin', () {
      when(() => auth.currentUser).thenReturn(null);

      final cubit = AdminDashboardCubit(giveawayRepository, client, winnerRepository);
      cubit.subscribeToRealtime();

      verifyNever(() => client.channel(any()));
    });

    test('close() removes the subscribed channel exactly once', () async {
      when(() => auth.currentUser).thenReturn(_adminUser);
      stubChannel(MockRealtimeChannel());

      final cubit = AdminDashboardCubit(giveawayRepository, client, winnerRepository);
      cubit.subscribeToRealtime();
      await cubit.close();

      verify(() => client.removeChannel(any())).called(1);
    });

    test('close() without ever subscribing does not throw', () async {
      final cubit = AdminDashboardCubit(giveawayRepository, client, winnerRepository);
      await cubit.close();
      verifyNever(() => client.removeChannel(any()));
    });
  });
}
