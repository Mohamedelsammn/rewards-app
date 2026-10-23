import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/core/error/app_exception.dart';
import 'package:rewardsapp/core/services/admob_service.dart';
import 'package:rewardsapp/features/rewarded_ads/domain/ad_reward_entities.dart';
import 'package:rewardsapp/features/rewarded_ads/presentation/rewarded_ads_cubit.dart';

const _status = AdRewardStatus(
  enabled: true,
  verification: AdRewardStatus.clientReported,
  ticketsPerCompletedAd: 25,
  dailyLimit: 10,
  usedToday: 2,
  remainingToday: 8,
  cooldownSeconds: 120,
);

AdSession _session(AdSessionStatus status, {String id = 's1', int points = 25}) =>
    AdSession(id: id, status: status, tickets: points);

/// Scripted backend. Claims answer from [claims] in order (an [Object]
/// that is an exception is thrown).
class _Repository implements AdRewardsRepository {
  _Repository({this.status$ = _status, List<Object>? claims, this.createError})
    : claims = claims ?? [AdClaim(session: _session(AdSessionStatus.credited), tickets: 120)];

  AdRewardStatus status$;
  final List<Object> claims;
  final Object? createError;
  final deviceIds = <String>[];
  final claimedIds = <String>[];
  int created = 0;
  int statusCalls = 0;
  Completer<void>? claimGate;

  @override
  Future<AdRewardStatus> status(String deviceId) async {
    deviceIds.add(deviceId);
    statusCalls++;
    return status$;
  }

  @override
  Future<AdSession> createSession({required String deviceId, required String adUnitId}) async {
    deviceIds.add(deviceId);
    created++;
    if (createError != null) throw createError!;
    return _session(AdSessionStatus.pending);
  }

  @override
  Future<AdSession> session(String id) => throw UnimplementedError('no polling');

  @override
  Future<AdClaim> claim(String sessionId) async {
    claimedIds.add(sessionId);
    await claimGate?.future;
    final answer = claims.length > 1 ? claims.removeAt(0) : claims.first;
    if (answer is AdClaim) return answer;
    throw answer;
  }
}

class _Presenter implements RewardedAdPresenter {
  _Presenter(this.outcome);

  RewardedAdOutcome outcome;
  int shown = 0;

  /// When set, the ad stays up until it completes.
  Completer<void>? hold;

  @override
  String get adUnitId => 'earn-unit';

  @override
  Future<RewardedAdOutcome> show() async {
    shown++;
    await hold?.future;
    return outcome;
  }
}

void main() {
  late int credited;

  RewardedAdsCubit build(
    _Repository repository,
    _Presenter presenter, {
    bool enabled = true,
    PendingAdSessions? pending,
  }) => RewardedAdsCubit(
    repository: repository,
    presenter: presenter,
    deviceId: () async => 'install-1',
    featureEnabled: enabled,
    onCredited: () => credited++,
    pending: pending,
    claimRetryDelays: const [Duration(milliseconds: 1), Duration(milliseconds: 1)],
  );

  setUp(() => credited = 0);

  group('status and eligibility', () {
    test('CLIENT_REPORTED status enables watching; points come from the server', () async {
      final cubit = build(_Repository(), _Presenter(RewardedAdOutcome.completed));
      await cubit.loadStatus();
      expect(cubit.state.phase, EarnPhase.ready);
      expect(cubit.state.status!.ticketsPerCompletedAd, 25);
    });

    test('another verification mode (old SSV) is never used', () async {
      final repository = _Repository(
        status$: const AdRewardStatus(enabled: true, verification: 'ADMOB_SSV'),
      );
      final presenter = _Presenter(RewardedAdOutcome.completed);
      final cubit = build(repository, presenter);
      await cubit.loadStatus();
      expect(cubit.state.phase, EarnPhase.disabled);
      await cubit.watch();
      expect(repository.created, 0);
      expect(presenter.shown, 0);
    });

    test('feature off by config or server: no session, no ad', () async {
      final repository = _Repository(
        status$: const AdRewardStatus(enabled: false, verification: 'CLIENT_REPORTED'),
      );
      final presenter = _Presenter(RewardedAdOutcome.completed);
      var cubit = build(repository, presenter);
      await cubit.loadStatus();
      await cubit.watch();
      expect(cubit.state.phase, EarnPhase.disabled);
      expect(repository.created, 0);

      cubit = build(_Repository(), presenter, enabled: false);
      await cubit.loadStatus();
      expect(cubit.state.phase, EarnPhase.disabled);
      expect(presenter.shown, 0);
    });

    test('the stable install id is used for status and sessions', () async {
      final repository = _Repository();
      final cubit = build(repository, _Presenter(RewardedAdOutcome.completed));
      await cubit.loadStatus();
      await cubit.watch();
      expect(repository.deviceIds.toSet(), {'install-1'});
    });
  });

  group('sessions', () {
    test('the session is created before the ad', () async {
      final repository = _Repository();
      final presenter = _Presenter(RewardedAdOutcome.completed)..hold = Completer<void>();
      final cubit = build(repository, presenter);
      await cubit.loadStatus();
      final watching = cubit.watch();
      await Future<void>.delayed(Duration.zero);
      expect(repository.created, 1);
      expect(presenter.shown, 1);
      presenter.hold!.complete();
      await watching;
    });

    for (final code in [
      'COOLDOWN',
      'DAILY_LIMIT_REACHED',
      'TOO_MANY_PENDING',
      'FEATURE_DISABLED',
    ]) {
      test('session refused ($code): no ad, error shown', () async {
        final repository = _Repository(createError: AppException(code: code, statusCode: 429));
        final presenter = _Presenter(RewardedAdOutcome.completed);
        final cubit = build(repository, presenter);
        await cubit.loadStatus();
        await cubit.watch();
        expect(presenter.shown, 0);
        expect(cubit.state.phase, EarnPhase.failed);
        expect((cubit.state.error! as AppException).code, code);
        expect(credited, 0);
      });
    }

    test('a malformed session response: no ad', () async {
      final repository = _Repository(
        createError: const AppException(code: AppException.badResponse),
      );
      final presenter = _Presenter(RewardedAdOutcome.completed);
      final cubit = build(repository, presenter);
      await cubit.loadStatus();
      await cubit.watch();
      expect(presenter.shown, 0);
      expect(cubit.state.phase, EarnPhase.failed);
    });

    test('repeated taps open one session and one ad', () async {
      final repository = _Repository();
      final presenter = _Presenter(RewardedAdOutcome.completed);
      final cubit = build(repository, presenter);
      await cubit.loadStatus();
      await Future.wait([cubit.watch(), cubit.watch(), cubit.watch()]);
      expect(repository.created, 1);
      expect(presenter.shown, 1);
      expect(repository.claimedIds, ['s1']);
    });
  });

  group('rewarded ad', () {
    test('reward earned → claim → CREDITED → wallet reload and server points', () async {
      final repository = _Repository();
      final cubit = build(repository, _Presenter(RewardedAdOutcome.completed));
      await cubit.loadStatus();
      await cubit.watch();
      expect(repository.claimedIds, ['s1']);
      expect(cubit.state.phase, EarnPhase.credited);
      expect(cubit.state.creditedTickets, 25, reason: 'from the claim, never hardcoded');
      expect(credited, 1);
    });

    for (final outcome in [
      RewardedAdOutcome.dismissedEarly,
      RewardedAdOutcome.failedToLoad,
      RewardedAdOutcome.failedToShow,
      RewardedAdOutcome.unsupported,
    ]) {
      test('${outcome.name}: no claim, no points', () async {
        final repository = _Repository();
        final cubit = build(repository, _Presenter(outcome));
        await cubit.loadStatus();
        await cubit.watch();
        expect(repository.claimedIds, isEmpty);
        expect(cubit.state.phase, EarnPhase.notCredited);
        expect(cubit.state.outcome, outcome);
        expect(credited, 0);
      });
    }

    test('duplicate triggers never claim the same session twice at once', () async {
      final pending = PendingAdSessions();
      final repository = _Repository()..claimGate = Completer<void>();
      final cubit = build(repository, _Presenter(RewardedAdOutcome.completed), pending: pending);
      await cubit.loadStatus();
      final watching = cubit.watch();
      await Future<void>.delayed(Duration.zero);
      // A second trigger for the same session while the claim runs.
      final again = cubit.reconcile();
      repository.claimGate!.complete();
      await Future.wait([watching, again]);
      expect(repository.claimedIds, ['s1']);
      expect(credited, 1);
    });
  });

  group('claims', () {
    test('verifiedAt null is fine: CREDITED is what counts', () async {
      final repository = _Repository(
        claims: [
          AdClaim(
            session: AdSession(
              id: 's1',
              status: AdSessionStatus.credited,
              tickets: 25,
              creditedAt: DateTime.utc(2026, 10, 22, 12, 1),
            ),
            tickets: 120,
          ),
        ],
      );
      final cubit = build(repository, _Presenter(RewardedAdOutcome.completed));
      await cubit.loadStatus();
      await cubit.watch();
      expect(cubit.state.phase, EarnPhase.credited);
    });

    test('a timeout retries the same session id, then credits', () async {
      final repository = _Repository(
        claims: [
          const AppException(code: AppException.timeout),
          const AppException(code: 'SERVER_ERROR', statusCode: 503),
          AdClaim(session: _session(AdSessionStatus.credited), tickets: 120),
        ],
      );
      final cubit = build(repository, _Presenter(RewardedAdOutcome.completed));
      await cubit.loadStatus();
      await cubit.watch();
      expect(repository.claimedIds, ['s1', 's1', 's1']);
      expect(repository.created, 1, reason: 'never a new session for a retry');
      expect(cubit.state.phase, EarnPhase.credited);
      expect(credited, 1);
    });

    test('still uncertain after the retries: Check again claims the same session', () async {
      final pending = PendingAdSessions();
      final repository = _Repository(
        claims: [
          const AppException(code: AppException.network),
          const AppException(code: AppException.network),
          const AppException(code: AppException.network),
          AdClaim(session: _session(AdSessionStatus.credited), tickets: 120),
        ],
      );
      final cubit = build(repository, _Presenter(RewardedAdOutcome.completed), pending: pending);
      await cubit.loadStatus();
      await cubit.watch();
      expect(cubit.state.phase, EarnPhase.stillPending);
      expect(cubit.state.pendingSessionId, 's1');
      expect(credited, 0);
      expect(pending.ids, ['s1']);

      await cubit.reconcile();
      expect(repository.claimedIds, ['s1', 's1', 's1', 's1']);
      expect(cubit.state.phase, EarnPhase.credited);
      expect(pending.ids, isEmpty);
      expect(credited, 1);
    });

    test('an already credited session answers the same (idempotent retry)', () async {
      final repository = _Repository(
        claims: [AdClaim(session: _session(AdSessionStatus.credited), tickets: 120)],
      );
      final cubit = build(repository, _Presenter(RewardedAdOutcome.completed));
      await cubit.loadStatus();
      await cubit.watch();
      await cubit.reconcile(); // no pending session any more: nothing sent
      expect(repository.claimedIds, ['s1']);
      expect(credited, 1);
    });

    test('COOLDOWN on the claim keeps the session pending for a later retry', () async {
      final pending = PendingAdSessions();
      final repository = _Repository(
        claims: [
          const AppException(code: 'COOLDOWN', statusCode: 429, details: {'retryAfter': 87}),
          AdClaim(session: _session(AdSessionStatus.credited), tickets: 120),
        ],
      );
      final cubit = build(repository, _Presenter(RewardedAdOutcome.completed), pending: pending);
      await cubit.loadStatus();
      await cubit.watch();
      expect(repository.claimedIds, ['s1'], reason: 'COOLDOWN is not retried automatically');
      expect(cubit.state.phase, EarnPhase.stillPending);
      expect((cubit.state.error! as AppException).retryAfterSeconds, 87);
      expect(pending.ids, ['s1']);
      await cubit.reconcile();
      expect(cubit.state.phase, EarnPhase.credited);
    });

    test('SESSION_EXPIRED: discarded, a fresh attempt is offered', () async {
      final pending = PendingAdSessions();
      final repository = _Repository(
        claims: [const AppException(code: 'SESSION_EXPIRED', statusCode: 410)],
      );
      final cubit = build(repository, _Presenter(RewardedAdOutcome.completed), pending: pending);
      await cubit.loadStatus();
      await cubit.watch();
      expect(cubit.state.phase, EarnPhase.notCredited);
      expect(cubit.state.rejectReason, 'EXPIRED');
      expect(pending.ids, isEmpty);
      expect(cubit.state.busy, isFalse);
      expect(credited, 0);
    });

    for (final code in [
      'SESSION_NOT_FOUND',
      'SESSION_NOT_OWNED',
      'ACCOUNT_INACTIVE',
      'AD_UNIT_NOT_ALLOWED',
      'DAILY_LIMIT_REACHED',
    ]) {
      test('$code on the claim: error, no points, not retried', () async {
        final pending = PendingAdSessions();
        final repository = _Repository(claims: [AppException(code: code, statusCode: 403)]);
        final cubit = build(repository, _Presenter(RewardedAdOutcome.completed), pending: pending);
        await cubit.loadStatus();
        await cubit.watch();
        expect(repository.claimedIds, ['s1']);
        expect(cubit.state.phase, EarnPhase.failed);
        expect((cubit.state.error! as AppException).code, code);
        expect(pending.ids, isEmpty);
        expect(credited, 0);
      });
    }

    test('an unexpected status or another session id credits nothing', () async {
      var repository = _Repository(claims: [AdClaim(session: _session(AdSessionStatus.rejected))]);
      var cubit = build(repository, _Presenter(RewardedAdOutcome.completed));
      await cubit.loadStatus();
      await cubit.watch();
      expect(cubit.state.phase, EarnPhase.notCredited);

      repository = _Repository(
        claims: [AdClaim(session: _session(AdSessionStatus.credited, id: 'other'))],
      );
      cubit = build(repository, _Presenter(RewardedAdOutcome.completed));
      await cubit.loadStatus();
      await cubit.watch();
      expect(cubit.state.phase, EarnPhase.stillPending);
      expect(credited, 0);
    });
  });

  group('lifecycle', () {
    test('leaving the screen during a claim: no emit, no wallet reload', () async {
      final repository = _Repository()..claimGate = Completer<void>();
      final cubit = build(repository, _Presenter(RewardedAdOutcome.completed));
      await cubit.loadStatus();
      final watching = cubit.watch();
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
      repository.claimGate!.complete();
      await expectLater(watching, completes);
      expect(credited, 0);
    });

    test('sign-out drops pending rewards of the previous account', () async {
      final pending = PendingAdSessions()..add('a-session');
      pending.clear();
      final repository = _Repository();
      final cubit = build(repository, _Presenter(RewardedAdOutcome.completed), pending: pending);
      await cubit.loadStatus();
      expect(repository.claimedIds, isEmpty);
    });

    test('reopening the page claims an unconfirmed reward once (same id)', () async {
      final pending = PendingAdSessions()..add('s9');
      final repository = _Repository(
        claims: [AdClaim(session: _session(AdSessionStatus.credited, id: 's9'), tickets: 120)],
      );
      final cubit = build(repository, _Presenter(RewardedAdOutcome.completed), pending: pending);
      await cubit.loadStatus();
      expect(repository.claimedIds, ['s9']);
      expect(cubit.state.phase, EarnPhase.credited);
      expect(pending.ids, isEmpty);
      // Loading again (e.g. after resume) does not claim again.
      await cubit.loadStatus();
      expect(repository.claimedIds, ['s9']);
      expect(credited, 1);
    });
  });
}
