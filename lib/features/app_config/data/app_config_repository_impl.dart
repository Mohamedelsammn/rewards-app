import '../../../core/localization/localized_text.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/cursor_page.dart';
import '../domain/app_config.dart';

class AppConfigRepositoryImpl implements AppConfigRepository {
  const AppConfigRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  /// Runs while the splash waits (and on resume): startup budget.
  Future<AppConfig> fetch() async =>
      parseAppConfig(await _api.get('/app-config', auth: false, budget: RequestBudget.startup));
}

AppConfig parseAppConfig(Map<String, dynamic> json) {
  final features = json['features'] is Map ? json['features'] as Map : const {};
  final ads = json['adRewards'] is Map ? json['adRewards'] as Map : const {};
  return AppConfig(
    minVersion: json['minVersion'] as String? ?? '0.0.0',
    latestVersion: json['latestVersion'] as String? ?? '0.0.0',
    maintenance: json['maintenance'] == true,
    maintenanceMessage: LocalizedText.fromJson(json['maintenanceMessage']),
    storeUrl: json['storeUrl'] as String? ?? '',
    privacyUrl: json['privacyUrl'] as String? ?? '',
    termsUrl: json['termsUrl'] as String? ?? '',
    adRewardsEnabled: features['adRewards'] == true && ads['enabled'] == true,
    socialProductsEnabled: features['socialProducts'] == true,
    pointsPerCompletedAd: parseInt(ads['pointsPerCompletedAd']),
    serverTime: parseDate(json['serverTime']),
  );
}
