import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/environment.dart';
import 'http_client_factory.dart';

/// Version reporting + update checking against the backend.
///
/// All calls are fire-and-forget safe: failures are logged and swallowed so
/// they never block or break app startup.
class AppUpdateService {
  static EnvironmentSettings get _env => EnvironmentConfig.settings;

  static Future<PackageInfo> _info() => PackageInfo.fromPlatform();

  /// Installed version as "1.0.0+45".
  static Future<String> installedVersion() async {
    final i = await _info();
    return '${i.version}+${i.buildNumber}';
  }

  /// Installed versionCode (the "+45" build number).
  static Future<int> installedVersionCode() async {
    final i = await _info();
    return int.tryParse(i.buildNumber) ?? 0;
  }

  /// Latest published app metadata from the backend (GitHub-backed).
  /// Returns null on failure or when unreachable.
  static Future<Map<String, dynamic>?> fetchLatest() async {
    try {
      final client = createPlatformHttpClient();
      final resp = await client
          .get(Uri.parse('${_env.userServiceUrl}/api/app/version'))
          .timeout(_env.apiTimeout);
      if (resp.statusCode == 200) {
        return json.decode(resp.body) as Map<String, dynamic>;
      }
      debugPrint('AppUpdateService.fetchLatest status ${resp.statusCode}');
    } catch (e) {
      debugPrint('AppUpdateService.fetchLatest: $e');
    }
    return null;
  }

  /// True when a newer version is published than the one installed.
  static Future<bool> isUpdateAvailable() async {
    final latest = await fetchLatest();
    if (latest == null) return false;
    final latestCode = (latest['versionCode'] as num?)?.toInt() ?? 0;
    return latestCode > await installedVersionCode();
  }

  /// Tell the backend which version this device runs. Fire-and-forget.
  static Future<void> reportVersion({String? keycloakId}) async {
    try {
      final i = await _info();
      final client = createPlatformHttpClient();
      await client
          .post(
            Uri.parse('${_env.userServiceUrl}/api/app/version/report'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'keycloakId': keycloakId,
              'versionName': i.version,
              'versionCode': int.tryParse(i.buildNumber) ?? 0,
              'platform': defaultTargetPlatform.name,
              'deviceModel': _deviceModel(),
            }),
          )
          .timeout(_env.apiTimeout);
    } catch (e) {
      debugPrint('AppUpdateService.reportVersion: $e');
    }
  }

  static String _deviceModel() {
    try {
      if (kIsWeb) return 'web';
      return Platform.operatingSystemVersion;
    } catch (_) {
      return 'unknown';
    }
  }
}
