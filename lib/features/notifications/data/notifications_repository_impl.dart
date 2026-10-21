import '../../../core/constants/app_constants.dart';
import '../../../core/localization/localized_text.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/cursor_page.dart';
import '../domain/notification_entities.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<CursorPage<AppNotification>> notifications({
    bool unreadOnly = false,
    String? cursor,
  }) async => CursorPage.fromJson(
    await _api.get(
      '/notifications',
      query: {
        'unreadOnly': unreadOnly ? 'true' : null,
        'cursor': cursor,
        'limit': AppConstants.pageSize,
      },
    ),
    parseNotification,
  );

  @override
  Future<int> unreadCount() async =>
      parseInt((await _api.get('/notifications/unread-count'))['count']);

  @override
  Future<AppNotification> notification(String id) async => parseNotification(
    Map<String, dynamic>.from((await _api.get('/notifications/$id'))['notification'] as Map),
  );

  @override
  Future<void> markRead(String id) => _api.post('/notifications/$id/read');

  @override
  Future<void> markAllRead() => _api.post('/notifications/read-all');

  @override
  Future<NotificationPreferences> preferences() async =>
      _parsePreferences(await _api.get('/me/notification-preferences'));

  @override
  Future<NotificationPreferences> updatePreferences(NotificationPreferences preferences) async =>
      _parsePreferences(
        await _api.put(
          '/me/notification-preferences',
          body: {
            'orders': preferences.orders,
            'giveaways': preferences.giveaways,
            'announcements': preferences.announcements,
          },
        ),
      );

  @override
  Future<void> registerDevice({
    required String installationId,
    required String? fcmToken,
    required String platform,
    required String appVersion,
    required String language,
  }) => _api.put(
    '/devices/$installationId',
    body: {
      'fcmToken': fcmToken,
      'platform': platform,
      'appVersion': appVersion,
      'language': language,
    },
  );

  @override
  Future<void> unregisterDevice(String installationId) => _api.delete('/devices/$installationId');

  NotificationPreferences _parsePreferences(Map<String, dynamic> json) {
    final prefs = json['preferences'] is Map ? json['preferences'] as Map : const {};
    return NotificationPreferences(
      orders: prefs['orders'] != false,
      giveaways: prefs['giveaways'] != false,
      announcements: prefs['announcements'] == true,
    );
  }
}

AppNotification parseNotification(Map<String, dynamic> json) {
  final data = json['data'] is Map ? json['data'] as Map : const {};
  return AppNotification(
    id: '${json['id']}',
    type: notificationTypeFrom(json['type'] as String?),
    title: LocalizedText.fromJson(json['title']),
    body: LocalizedText.fromJson(json['body']),
    data: {for (final entry in data.entries) '${entry.key}': '${entry.value}'},
    read: json['read'] == true,
    createdAt: parseDate(json['createdAt']),
  );
}
