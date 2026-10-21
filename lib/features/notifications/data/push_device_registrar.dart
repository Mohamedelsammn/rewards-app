import 'package:flutter/foundation.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/security/secure_token_storage.dart';
import '../../../core/services/push_notification_service.dart';
import '../domain/notification_entities.dart';

/// `PUT/DELETE /devices/{installationId}` for this installation.
class PushDeviceRegistrarImpl implements PushDeviceRegistrar {
  const PushDeviceRegistrarImpl(this._repository, this._storage, this._appInfo);

  final NotificationsRepository _repository;
  final SecureTokenStorage _storage;
  final AppInfo _appInfo;

  @override
  Future<void> register({required String? fcmToken, required String language}) async =>
      _repository.registerDevice(
        installationId: await _storage.installationId(),
        fcmToken: fcmToken,
        platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        appVersion: _appInfo.version,
        language: language,
      );

  @override
  Future<void> unregister() async => _repository.unregisterDevice(await _storage.installationId());
}
