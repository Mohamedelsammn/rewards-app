import 'package:equatable/equatable.dart';

import '../../../core/localization/localized_text.dart';

/// `GET /app-config`: version gate, maintenance, feature flags and links.
class AppConfig extends Equatable {
  const AppConfig({
    this.minVersion = '0.0.0',
    this.latestVersion = '0.0.0',
    this.maintenance = false,
    this.maintenanceMessage = const LocalizedText(),
    this.storeUrl = '',
    this.privacyUrl = '',
    this.termsUrl = '',
    this.adRewardsEnabled = false,
    this.socialProductsEnabled = false,
    this.ticketsPerCompletedAd = 0,
    this.serverTime,
  });

  final String minVersion;
  final String latestVersion;
  final bool maintenance;
  final LocalizedText maintenanceMessage;
  final String storeUrl;
  final String privacyUrl;
  final String termsUrl;

  /// True only when both `features.adRewards` and `adRewards.enabled` are on.
  final bool adRewardsEnabled;
  final bool socialProductsEnabled;
  final int ticketsPerCompletedAd;
  final DateTime? serverTime;

  /// Whether [appVersion] (e.g. `1.1.1`) is older than [minVersion].
  bool requiresUpdate(String appVersion) => compareVersions(appVersion, minVersion) < 0;

  @override
  List<Object?> get props => [
    minVersion,
    latestVersion,
    maintenance,
    maintenanceMessage,
    storeUrl,
    privacyUrl,
    termsUrl,
    adRewardsEnabled,
    socialProductsEnabled,
    ticketsPerCompletedAd,
  ];
}

/// Compares dotted numeric versions; build metadata after `+` is ignored.
int compareVersions(String a, String b) {
  List<int> parts(String value) => value
      .split('+')
      .first
      .split('.')
      .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();
  final left = parts(a);
  final right = parts(b);
  for (var i = 0; i < 3; i++) {
    final l = i < left.length ? left[i] : 0;
    final r = i < right.length ? right[i] : 0;
    if (l != r) return l.compareTo(r);
  }
  return 0;
}

abstract interface class AppConfigRepository {
  Future<AppConfig> fetch();
}
