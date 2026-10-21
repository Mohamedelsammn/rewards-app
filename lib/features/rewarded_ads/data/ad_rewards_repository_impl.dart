import '../../../core/network/api_client.dart';
import '../../../core/utils/cursor_page.dart';
import '../domain/ad_reward_entities.dart';

class AdRewardsRepositoryImpl implements AdRewardsRepository {
  const AdRewardsRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<AdRewardStatus> status(String deviceId) async {
    final json = await _api.get('/ad-rewards/status', query: {'deviceId': deviceId});
    return AdRewardStatus(
      enabled: json['enabled'] == true,
      pointsPerCompletedAd: parseInt(json['pointsPerCompletedAd']),
      dailyLimit: parseInt(json['dailyLimit']),
      usedToday: parseInt(json['usedToday']),
      remainingToday: parseInt(json['remainingToday']),
      cooldownSeconds: parseInt(json['cooldownSeconds']),
      nextAvailableAt: parseDate(json['nextAvailableAt']),
    );
  }

  @override
  Future<({AdSession session, SsvOptions ssv})> createSession({
    required String deviceId,
    required String adUnitId,
  }) async {
    final json = await _api.post(
      '/ad-rewards/sessions',
      body: {'deviceId': deviceId, 'adUnitId': adUnitId},
    );
    final ssv = Map<String, dynamic>.from(json['ssv'] as Map);
    return (
      session: parseAdSession(Map<String, dynamic>.from(json['session'] as Map)),
      ssv: SsvOptions(userId: '${ssv['userId']}', customData: '${ssv['customData']}'),
    );
  }

  @override
  Future<AdSession> session(String id) async => parseAdSession(
    Map<String, dynamic>.from((await _api.get('/ad-rewards/sessions/$id'))['session'] as Map),
  );
}

AdSession parseAdSession(Map<String, dynamic> json) => AdSession(
  id: '${json['id']}',
  status: switch (json['status']) {
    'CREDITED' => AdSessionStatus.credited,
    'REJECTED' => AdSessionStatus.rejected,
    'EXPIRED' => AdSessionStatus.expired,
    _ => AdSessionStatus.pending,
  },
  points: parseInt(json['points']),
  rejectReason: json['rejectReason'] as String?,
  expiresAt: parseDate(json['expiresAt']),
);
