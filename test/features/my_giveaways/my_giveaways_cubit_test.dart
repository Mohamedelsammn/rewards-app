import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/error/failure.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/my_giveaways/presentation/bloc/my_giveaways_cubit.dart';
import 'package:rewardsapp/features/my_giveaways/presentation/bloc/my_giveaways_state.dart';
import 'package:rewardsapp/services/secure_storage_service.dart';
import 'package:rewardsapp/shared/models/participation.dart';
import 'package:rewardsapp/shared/repositories/participation_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockParticipationRepository extends Mock implements ParticipationRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class _FakeRealtimeChannel extends Fake implements RealtimeChannel {}

PostgresChangePayload _payload({
  required String table,
  PostgresChangeEvent eventType = PostgresChangeEvent.insert,
  Map<String, dynamic> newRecord = const {},
}) => PostgresChangePayload(
  schema: 'public',
  table: table,
  commitTimestamp: DateTime(2026, 1, 1),
  eventType: eventType,
  newRecord: newRecord,
  oldRecord: const {},
  errors: null,
);

Participation _participation(
  String id,
  String giveawayId, {
  String status = 'active',
  bool isWinner = false,
}) => Participation(
  id: id,
  giveawayId: giveawayId,
  participationSequence: 1,
  participationNumber: 42,
  scratchRevealedAt: null,
  createdAt: DateTime(2026, 1, 1),
  giveaway: {'id': giveawayId, 'title': 'Prize', 'status': status},
  isWinner: isWinner,
);

void main() {
  late MockParticipationRepository repository;
  late MockSupabaseClient client;
  late MockSecureStorageService secureStorage;

  setUp(() {
    repository = MockParticipationRepository();
    client = MockSupabaseClient();
    secureStorage = MockSecureStorageService();
    when(() => repository.participationCreated).thenAnswer((_) => const Stream.empty());
    when(() => repository.patchCachedParticipationGiveaway(any(), any())).thenAnswer((_) async {});
  });

  final participation = _participation('p1', 'g1');

  group('MyGiveawaysCubit', () {
    blocTest<MyGiveawaysCubit, MyGiveawaysState>(
      'emits empty when there are no participations',
      build: () => MyGiveawaysCubit(repository, client, secureStorage),
      setUp: () {
        when(() => repository.peekCachedParticipations()).thenReturn(null);
        when(
          () => repository.getMyParticipations(forceRefresh: true),
        ).thenAnswer((_) async => const Result.success([]));
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const MyGiveawaysState(status: MyGiveawaysStatus.loading),
        const MyGiveawaysState(status: MyGiveawaysStatus.empty, participations: []),
      ],
    );

    blocTest<MyGiveawaysCubit, MyGiveawaysState>(
      'emits loaded with participations on success',
      build: () => MyGiveawaysCubit(repository, client, secureStorage),
      setUp: () {
        when(() => repository.peekCachedParticipations()).thenReturn(null);
        when(
          () => repository.getMyParticipations(forceRefresh: true),
        ).thenAnswer((_) async => Result.success([participation]));
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const MyGiveawaysState(status: MyGiveawaysStatus.loading),
        MyGiveawaysState(status: MyGiveawaysStatus.loaded, participations: [participation]),
      ],
    );

    blocTest<MyGiveawaysCubit, MyGiveawaysState>(
      'emits error on failure',
      build: () => MyGiveawaysCubit(repository, client, secureStorage),
      setUp: () {
        when(() => repository.peekCachedParticipations()).thenReturn(null);
        when(
          () => repository.getMyParticipations(forceRefresh: true),
        ).thenAnswer((_) async => const Result.failure(NetworkFailure()));
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const MyGiveawaysState(status: MyGiveawaysStatus.loading),
        const MyGiveawaysState(status: MyGiveawaysStatus.error, failure: NetworkFailure()),
      ],
    );

    blocTest<MyGiveawaysCubit, MyGiveawaysState>(
      'a warm cache is shown immediately, but is still authoritatively reconciled against '
      'the server -- a giveaway that ended while nothing was subscribed to realtime must not '
      'keep showing as active just because its TTL hasn\'t expired yet',
      build: () => MyGiveawaysCubit(repository, client, secureStorage),
      setUp: () {
        when(
          () => repository.peekCachedParticipations(),
        ).thenReturn([_participation('p1', 'g1', status: 'active')]);
        when(() => repository.getMyParticipations(forceRefresh: true)).thenAnswer(
          (_) async => Result.success([
            _participation('p1', 'g1', status: 'ended', isWinner: true),
          ]),
        );
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        MyGiveawaysState(
          status: MyGiveawaysStatus.loaded,
          participations: [_participation('p1', 'g1', status: 'active')],
        ),
        MyGiveawaysState(
          status: MyGiveawaysStatus.loaded,
          participations: [_participation('p1', 'g1', status: 'ended', isWinner: true)],
        ),
      ],
    );

    blocTest<MyGiveawaysCubit, MyGiveawaysState>(
      'a background (realtime-triggered) refresh with data already on screen never re-shows '
      'the loading state',
      build: () => MyGiveawaysCubit(repository, client, secureStorage),
      seed: () => MyGiveawaysState(status: MyGiveawaysStatus.loaded, participations: [participation]),
      setUp: () => when(
        () => repository.getMyParticipations(forceRefresh: true),
      ).thenAnswer((_) async => Result.success([participation])),
      act: (cubit) => cubit.load(forceRefresh: true),
      expect: () => <MyGiveawaysState>[],
    );
  });

  group('MyGiveawaysCubit local participationCreated signal', () {
    test(
      'reloads immediately (no realtime round trip) the moment this device confirms creating '
      'a participation',
      () async {
        final controller = StreamController<Participation>.broadcast();
        addTearDown(controller.close);
        when(() => repository.participationCreated).thenAnswer((_) => controller.stream);
        when(
          () => repository.getMyParticipations(forceRefresh: true),
        ).thenAnswer((_) async => Result.success([participation]));

        final cubit = MyGiveawaysCubit(repository, client, secureStorage);
        controller.add(participation);
        // No debounce on this path -- a single deterministic local event,
        // not a realtime burst -- so no artificial delay should be needed
        // beyond letting the stream's microtask/event-loop turn complete.
        await Future<void>.delayed(Duration.zero);

        verify(() => repository.getMyParticipations(forceRefresh: true)).called(1);
        await cubit.close();
      },
    );
  });

  group('MyGiveawaysCubit realtime lifecycle', () {
    setUpAll(() {
      registerFallbackValue(PostgresChangeEvent.all);
      registerFallbackValue(_FakeRealtimeChannel());
    });

    final capturedCallbacks = <String, void Function(PostgresChangePayload)>{};

    void stubChannels() {
      capturedCallbacks.clear();
      when(() => client.channel(any())).thenAnswer((invocation) {
        final name = invocation.positionalArguments.first as String;
        final channel = MockRealtimeChannel();
        when(
          () => channel.onPostgresChanges(
            event: any(named: 'event'),
            schema: any(named: 'schema'),
            table: any(named: 'table'),
            filter: any(named: 'filter'),
            callback: captureAny(named: 'callback'),
          ),
        ).thenAnswer((invocation) {
          capturedCallbacks[name] =
              invocation.namedArguments[#callback] as void Function(PostgresChangePayload);
          return channel;
        });
        when(() => channel.subscribe()).thenReturn(channel);
        return channel;
      });
      when(() => client.removeChannel(any())).thenAnswer((_) async => 'ok');
    }

    test('opens exactly 4 scoped channels, and a second call is a no-op', () async {
      when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-1');
      stubChannels();

      final cubit = MyGiveawaysCubit(repository, client, secureStorage);
      await cubit.subscribeToRealtime();
      await cubit.subscribeToRealtime();

      verify(() => client.channel('my-giveaways-participations-user-1')).called(1);
      verify(() => client.channel('my-giveaways-winner-notifications-user-1')).called(1);
      verify(() => client.channel('my-giveaways-status-user-1')).called(1);
      verify(() => client.channel('my-giveaways-winners-user-1')).called(1);
      await cubit.close();
    });

    test('never subscribes when there is no cached identity', () async {
      when(() => secureStorage.cachedUserId).thenAnswer((_) async => null);

      final cubit = MyGiveawaysCubit(repository, client, secureStorage);
      await cubit.subscribeToRealtime();

      verifyNever(() => client.channel(any()));
      await cubit.close();
    });

    test(
      'a giveaways UPDATE patches just the affected card in place, immediately, with no '
      'network round trip',
      () async {
        when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-1');
        stubChannels();

        final cubit = MyGiveawaysCubit(repository, client, secureStorage);
        // Seed state with an existing participation via a successful load.
        when(() => repository.peekCachedParticipations()).thenReturn(null);
        when(
          () => repository.getMyParticipations(forceRefresh: true),
        ).thenAnswer((_) async => Result.success([_participation('p1', 'g1', status: 'active')]));
        await cubit.load();
        await cubit.subscribeToRealtime();

        capturedCallbacks['my-giveaways-status-user-1']!(
          _payload(
            table: 'giveaways',
            eventType: PostgresChangeEvent.update,
            newRecord: const {'id': 'g1', 'title': 'Prize', 'status': 'ended'},
          ),
        );

        expect(cubit.state.participations.single.giveaway?['status'], 'ended');
        verify(() => repository.patchCachedParticipationGiveaway('p1', any())).called(1);
        await cubit.close();
      },
    );

    test(
      'a winners INSERT for one of my giveaways re-confirms that one participation from the '
      'server (never trusting the payload alone) and patches just that card',
      () async {
        when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-1');
        stubChannels();

        final cubit = MyGiveawaysCubit(repository, client, secureStorage);
        when(() => repository.peekCachedParticipations()).thenReturn(null);
        when(
          () => repository.getMyParticipations(forceRefresh: true),
        ).thenAnswer((_) async => Result.success([_participation('p1', 'g1', status: 'active')]));
        await cubit.load();
        await cubit.subscribeToRealtime();

        when(() => repository.getMyParticipationWithStatusForGiveaway('g1')).thenAnswer(
          (_) async => Result.success(_participation('p1', 'g1', status: 'ended', isWinner: true)),
        );

        capturedCallbacks['my-giveaways-winners-user-1']!(
          _payload(table: 'winners', newRecord: const {'giveaway_id': 'g1'}),
        );

        verifyNever(() => repository.getMyParticipationWithStatusForGiveaway('g1'));
        await Future<void>.delayed(const Duration(milliseconds: 600));

        verify(() => repository.getMyParticipationWithStatusForGiveaway('g1')).called(1);
        expect(cubit.state.participations.single.isWinner, isTrue);
        await cubit.close();
      },
    );

    test('a winners INSERT for a giveaway that is not mine is ignored', () async {
      when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-1');
      stubChannels();

      final cubit = MyGiveawaysCubit(repository, client, secureStorage);
      when(() => repository.peekCachedParticipations()).thenReturn(null);
      when(
        () => repository.getMyParticipations(forceRefresh: true),
      ).thenAnswer((_) async => Result.success([_participation('p1', 'g1', status: 'active')]));
      await cubit.load();
      await cubit.subscribeToRealtime();

      capturedCallbacks['my-giveaways-winners-user-1']!(
        _payload(table: 'winners', newRecord: const {'giveaway_id': 'not-mine'}),
      );
      await Future<void>.delayed(const Duration(milliseconds: 600));

      verifyNever(() => repository.getMyParticipationWithStatusForGiveaway(any()));
      await cubit.close();
    });

    test(
      'a winner_announcement notification re-confirms the affected participation from the '
      'server using the giveawayId in its payload -- never trusting the notification alone',
      () async {
        when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-1');
        stubChannels();

        final cubit = MyGiveawaysCubit(repository, client, secureStorage);
        when(() => repository.peekCachedParticipations()).thenReturn(null);
        when(
          () => repository.getMyParticipations(forceRefresh: true),
        ).thenAnswer((_) async => Result.success([_participation('p1', 'g1', status: 'active')]));
        await cubit.load();
        await cubit.subscribeToRealtime();

        when(() => repository.getMyParticipationWithStatusForGiveaway('g1')).thenAnswer(
          (_) async => Result.success(_participation('p1', 'g1', status: 'ended', isWinner: true)),
        );

        capturedCallbacks['my-giveaways-winner-notifications-user-1']!(
          _payload(
            table: 'notifications',
            newRecord: const {
              'type': 'winner_announcement',
              'data': {'giveawayId': 'g1', 'winnerId': 'w1'},
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 600));

        verify(() => repository.getMyParticipationWithStatusForGiveaway('g1')).called(1);
        expect(cubit.state.participations.single.isWinner, isTrue);
        await cubit.close();
      },
    );

    test(
      'a notification with no parseable giveawayId falls back to a full debounced reload '
      'rather than doing nothing',
      () async {
        when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-1');
        stubChannels();

        final cubit = MyGiveawaysCubit(repository, client, secureStorage);
        when(() => repository.peekCachedParticipations()).thenReturn(null);
        when(
          () => repository.getMyParticipations(forceRefresh: true),
        ).thenAnswer((_) async => const Result.success([]));
        await cubit.load();
        await cubit.subscribeToRealtime();

        capturedCallbacks['my-giveaways-winner-notifications-user-1']!(
          _payload(table: 'notifications', newRecord: const {'type': 'winner_announcement'}),
        );
        await Future<void>.delayed(const Duration(milliseconds: 600));

        verify(() => repository.getMyParticipations(forceRefresh: true)).called(2);
        await cubit.close();
      },
    );

    test('a participations INSERT triggers a single debounced forceRefresh reload', () async {
      when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-1');
      stubChannels();
      when(
        () => repository.getMyParticipations(forceRefresh: true),
      ).thenAnswer((_) async => Result.success([participation]));

      final cubit = MyGiveawaysCubit(repository, client, secureStorage);
      await cubit.subscribeToRealtime();
      capturedCallbacks['my-giveaways-participations-user-1']!(
        _payload(table: 'participations'),
      );

      verifyNever(() => repository.getMyParticipations(forceRefresh: true));
      await Future<void>.delayed(const Duration(milliseconds: 600));

      verify(() => repository.getMyParticipations(forceRefresh: true)).called(1);
      await cubit.close();
    });

    test('close() removes every subscribed channel exactly once', () async {
      when(() => secureStorage.cachedUserId).thenAnswer((_) async => 'user-1');
      stubChannels();

      final cubit = MyGiveawaysCubit(repository, client, secureStorage);
      await cubit.subscribeToRealtime();
      await cubit.close();

      verify(() => client.removeChannel(any())).called(4);
    });

    test('close() without ever subscribing does not throw', () async {
      final cubit = MyGiveawaysCubit(repository, client, secureStorage);
      await cubit.close();
      verifyNever(() => client.removeChannel(any()));
    });
  });
}
