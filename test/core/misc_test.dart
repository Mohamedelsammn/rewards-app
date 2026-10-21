import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/app/router/routes.dart';
import 'package:rewardsapp/core/config/environment.dart';
import 'package:rewardsapp/features/app_config/domain/app_config.dart';
import 'package:rewardsapp/features/notifications/domain/notification_entities.dart';
import 'package:rewardsapp/features/notifications/presentation/notification_navigation.dart';

void main() {
  group('Environment', () {
    test('only api mode with an https URL is accepted in release', () {
      const url = 'https://rewards-api.creativevpnapp.com/api/v1';
      expect(Environment.validate(dataMode: 'api', apiBaseUrl: url, releaseMode: true), isNull);
      expect(
        Environment.validate(dataMode: 'demo', apiBaseUrl: url, releaseMode: false),
        EnvironmentIssue.unsupportedDataMode,
      );
      expect(
        Environment.validate(dataMode: 'api', apiBaseUrl: '', releaseMode: false),
        EnvironmentIssue.apiNotConfigured,
      );
      expect(
        Environment.validate(
          dataMode: 'api',
          apiBaseUrl: 'http://10.0.2.2:3000/api/v1',
          releaseMode: true,
        ),
        EnvironmentIssue.insecureApiUrl,
      );
      expect(
        Environment.validate(
          dataMode: 'api',
          apiBaseUrl: 'http://10.0.2.2:3000/api/v1',
          releaseMode: false,
        ),
        isNull,
      );
    });

    test('defaults to the production API', () {
      expect(Environment.dataMode, 'api');
      expect(Environment.apiBaseUrl, 'https://rewards-api.creativevpnapp.com/api/v1');
    });
  });

  test('version comparison', () {
    expect(compareVersions('1.1.1', '1.0.0'), greaterThan(0));
    expect(compareVersions('1.0', '1.0.0'), 0);
    expect(compareVersions('1.9.0', '1.10.0'), lessThan(0));
  });

  group('notification targets', () {
    test('by type and data', () {
      expect(
        notificationTarget(NotificationType.orderStatus, const {'orderId': 'o1'}),
        Routes.order('o1'),
      );
      expect(
        notificationTarget(NotificationType.winnerSelected, const {'giveawayId': 'g1'}),
        Routes.myGiveaways,
      );
      expect(
        notificationTarget(NotificationType.giveawayResult, const {'giveawayId': 'g1'}),
        Routes.giveaway('g1'),
      );
      expect(notificationTarget(NotificationType.announcement, const {}), isNull);
      expect(notificationTarget(NotificationType.orderStatus, const {}), isNull);
    });

    test('push taps fall back to the inbox', () {
      expect(pushTarget(const {'type': 'ORDER_STATUS', 'orderId': 'o1'}), Routes.order('o1'));
      expect(
        pushTarget(const {'type': 'ANNOUNCEMENT', 'notificationId': 'n1'}),
        Routes.notification('n1'),
      );
      expect(pushTarget(const {}), Routes.notifications);
    });
  });

  test('English and Arabic ARB files have the same keys and placeholders', () {
    Map<String, dynamic> load(String lang) =>
        jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;
    final en = load('en');
    final ar = load('ar');
    final keys = en.keys.where((key) => !key.startsWith('@')).toSet();
    expect(ar.keys.where((key) => !key.startsWith('@')).toSet(), keys);
    for (final key in keys) {
      final meta = en['@$key'];
      final placeholders = meta is Map && meta['placeholders'] is Map
          ? (meta['placeholders'] as Map).keys.cast<String>()
          : const <String>[];
      for (final name in placeholders) {
        expect(ar[key] as String, contains('{$name'), reason: '$key is missing {$name}');
      }
      expect((ar[key] as String).contains('???'), isFalse, reason: 'corrupted Arabic in $key');
    }
  });
}
