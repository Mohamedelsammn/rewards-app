import '../../../core/error/app_exception.dart';
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
      verification: '${json['verification'] ?? ''}',
      ticketsPerCompletedAd: parseInt(json['ticketsPerCompletedAd']),
      dailyLimit: parseInt(json['dailyLimit']),
      usedToday: parseInt(json['usedToday']),
      remainingToday: parseInt(json['remainingToday']),
      cooldownSeconds: parseInt(json['cooldownSeconds']),
      nextAvailableAt: parseDate(json['nextAvailableAt']),
    );
  }

  @override
  Future<AdSession> createSession({required String deviceId, required String adUnitId}) async =>
      _session(
        await _api.post('/ad-rewards/sessions', body: {'deviceId': deviceId, 'adUnitId': adUnitId}),
      );

  @override
  Future<AdSession> session(String id) async =>
      _session(await _api.get('/ad-rewards/sessions/$id'));

  @override
  Future<AdClaim> claim(String sessionId) async {
    final json = await _api.post('/ad-rewards/claims', body: {'sessionId': sessionId});
    final tickets = json['tickets'];
    return AdClaim(session: _session(json), tickets: tickets == null ? null : parseInt(tickets));
  }

  /// `{ session: {...} }` with an id, or a bad-response error.
  static AdSession _session(Json json) {
    final session = json['session'];
    if (session is! Map || '${session['id'] ?? ''}'.isEmpty) {
      throw const AppException(code: AppException.badResponse, message: 'Missing ad session');
    }
    return parseAdSession(Map<String, dynamic>.from(session));
  }
}

AdSession parseAdSession(Map<String, dynamic> json) => AdSession(
  id: '${json['id']}',
  status: switch (json['status']) {
    'CREDITED' => AdSessionStatus.credited,
    'REJECTED' => AdSessionStatus.rejected,
    'EXPIRED' => AdSessionStatus.expired,
    _ => AdSessionStatus.pending,
  },
  tickets: parseInt(json['tickets']),
  rejectReason: json['rejectReason'] as String?,
  expiresAt: parseDate(json['expiresAt']),
  creditedAt: parseDate(json['creditedAt']),
);
