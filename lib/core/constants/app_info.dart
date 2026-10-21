import 'package:package_info_plus/package_info_plus.dart';

/// Installed app version, used for the `/app-config` version gate and push
/// device registration.
class AppInfo {
  const AppInfo({required this.version, required this.buildNumber});

  static Future<AppInfo> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return AppInfo(version: info.version, buildNumber: info.buildNumber);
    } catch (_) {
      return const AppInfo(version: '0.0.0', buildNumber: '0');
    }
  }

  final String version;
  final String buildNumber;
}
