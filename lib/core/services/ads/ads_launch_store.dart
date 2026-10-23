import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../security/secure_token_storage.dart';

/// Counts app launches, so the very first one never shows an App Open ad.
class AdsLaunchStore {
  AdsLaunchStore([FlutterSecureStorage? storage])
    : _storage = storage ?? SecureTokenStorage.secureStorage;

  final FlutterSecureStorage _storage;
  static const _key = 'ads_launch_count';

  /// Records this launch; returns how many launches came before it.
  Future<int> recordLaunch() async {
    int previous;
    try {
      previous = int.tryParse(await _storage.read(key: _key) ?? '') ?? 0;
      await _storage.write(key: _key, value: '${previous + 1}');
    } catch (_) {
      // Unreadable storage counts as a first launch (no ad).
      previous = 0;
    }
    return previous;
  }
}
