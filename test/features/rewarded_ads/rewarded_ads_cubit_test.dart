import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/core/services/admob_service.dart';
import 'package:rewardsapp/features/rewarded_ads/domain/ad_reward_entities.dart';
import 'package:rewardsapp/features/rewarded_ads/presentation/rewarded_ads_cubit.dart';

const _status = AdRewardStatus(
  enabled: true,
  pointsPerCompletedAd: 10,
  dailyLimit: 10,
  usedToday: 0,
  remainingToday: 10,
  cooldownSeconds: 0,
);

class _Repository implements AdRewardsRepository {
  _Repository(this.polls);

  /// Session statuses returned by successive polls.
  final List<AdSessionStatus> polls;
  int created = 0;
  String? deviceId;

  @override
  Future<AdRewardStatus> status(String deviceId) async {
    this.deviceId = deviceId;
    return _status;
  }

  @override
  Future<({AdSession session, SsvOptions ssv})> createSession({
    required String deviceId,
    required String adUnitId,
  }) async {
    created++;
    return (
      session: const AdSession(id: 's1', status: AdSessionStatus.pending, points: 10),
      ssv: const SsvOptions(userId: 'u1', customData: 's1'),
    );
  }

  @override
  Future<AdSession> session(String id) async => AdSession(
    id: id,
    status: polls.length > 1 ? polls.removeAt(0) : polls.first,
    points: 10,
    rejectReason: polls.first == AdSessionStatus.rejected ? 'INVALID_SIGNATURE' : null,
  );
}

class _Presenter implements RewardedAdPresenter {
  _Presenter(this.outcome);

  final RewardedAdOutcome outcome;
  ({String userId, String customData})? shownWith;

  @override
  String get adUnitId => 'test-unit';

  @override
  Future<RewardedAdOutcome> show({required String ssvUserId, required String ssvCustomData}) async {
    shownWith = (userId: ssvUserId, customData: ssvCustomData);
    return outcome;
  }
}

void main() {
  RewardedAdsCubit build(
    _Repository repository,
    _Presenter presenter, {
    bool enabled = true,
    void Function()? credited,
  }) => RewardedAdsCubit(
    repository: repository,
    presenter: presenter,
    deviceId: () async => 'install-1',
    featureEnabled: enabled,
    onCredited: credited ?? () {},
    pollInterval: const Duration(milliseconds: 1),
    pollTimeout: const Duration(milliseconds: 200),
  );

  test('disabled by app config: no server call', () async {
    final repository = _Repository([AdSessionStatus.pending]);
    final cubit = build(repository, _Presenter(RewardedAdOutcome.completed), enabled: false);
    await cubit.loadStatus();
    expect(cubit.state.phase, EarnPhase.disabled);
    expect(repository.deviceId, isNull);
  });

  test('passes SSV options to the ad and credits only after the server says so', () async {
    var credited = 0;
    final repository = _Repository([AdSessionStatus.pending, AdSessionStatus.credited]);
    final presenter = _Presenter(RewardedAdOutcome.completed);
    final cubit = build(repository, presenter, credited: () => credited++);
    await cubit.loadStatus();
    expect(repository.deviceId, 'install-1');

    await cubit.watch();

    expect(presenter.shownWith, (userId: 'u1', customData: 's1'));
    expect(cubit.state.phase, EarnPhase.credited);
    expect(cubit.state.creditedPoints, 10);
    expect(credited, 1);
  });

  test('a rejected session is reported and never credited', () async {
    var credited = 0;
    final cubit = build(
      _Repository([AdSessionStatus.rejected]),
      _Presenter(RewardedAdOutcome.completed),
      credited: () => credited++,
    );
    await cubit.loadStatus();
    await cubit.watch();
    expect(cubit.state.phase, EarnPhase.notCredited);
    expect(cubit.state.rejectReason, 'INVALID_SIGNATURE');
    expect(credited, 0);
  });

  test('closing the ad early does not poll', () async {
    final repository = _Repository([AdSessionStatus.credited]);
    final cubit = build(repository, _Presenter(RewardedAdOutcome.dismissedEarly));
    await cubit.loadStatus();
    await cubit.watch();
    expect(cubit.state.phase, EarnPhase.notCredited);
    expect(cubit.state.outcome, RewardedAdOutcome.dismissedEarly);
  });

  test('still pending after the timeout', () async {
    final cubit = build(
      _Repository([AdSessionStatus.pending]),
      _Presenter(RewardedAdOutcome.completed),
    );
    await cubit.loadStatus();
    await cubit.watch();
    expect(cubit.state.phase, EarnPhase.stillPending);
  });
}
