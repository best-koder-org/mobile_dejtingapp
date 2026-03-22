import 'dart:io';
import 'package:flutter/foundation.dart';

enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  static Environment _currentEnvironment =
      Environment.development; // Default to dev

  static Environment get current => _currentEnvironment;

  static void setEnvironment(Environment env) {
    _currentEnvironment = env;
  }

  // Easy way to check current environment
  static bool get isDevelopment =>
      _currentEnvironment == Environment.development;
  static bool get isStaging => _currentEnvironment == Environment.staging;
  static bool get isProduction => _currentEnvironment == Environment.production;

  // Environment-specific configurations
  static EnvironmentSettings get settings {
    switch (_currentEnvironment) {
      case Environment.development:
        return _developmentSettings;
      case Environment.staging:
        return _stagingSettings;
      case Environment.production:
        return _productionSettings;
    }
  }

  /// Staging Tailscale Funnel hostname.
  /// Set via: --dart-define=STAGING_HOST=fastdev.tailnet-xxx.ts.net
  static const String _stagingHost = String.fromEnvironment(
    'STAGING_HOST',
    defaultValue: 'CHANGE_ME.ts.net',
  );

  // Development environment (your main workspace)
  // MUST be a getter (not static final) so _getBaseUrl runs AFTER detectEmulator()
  static EnvironmentSettings get _developmentSettings => EnvironmentSettings(
    name: 'Development',
    userServiceUrl: _getBaseUrl(8082),
    matchmakingServiceUrl: _getBaseUrl(8083),
    photoServiceUrl: _getBaseUrl(8085), // FIXED: Match dev-start port 8085
    messagingServiceUrl: _getBaseUrl(8086), // ADDED: Messaging service
    swipeServiceUrl: _getBaseUrl(8087), // Updated to port 8087
    gatewayUrl: _getBaseUrl(8080),
    keycloakUrl: _getBaseUrl(8090),
    keycloakRealm: 'DatingApp',
    keycloakClientId: 'dejtingapp-flutter',
    keycloakScopes: const ['openid', 'profile', 'email', 'offline_access'],
    keycloakRedirectUri: 'dejtingapp://callback',
    apiTimeout: const Duration(seconds: 30),
    enableLogging: true,
    enableDebugMode: true,
    databaseName: 'dating_app_dev',
  );

  // Staging environment — Tailscale Funnel, all traffic through YARP gateway
  static EnvironmentSettings get _stagingSettings => EnvironmentSettings(
    name: 'Staging',
    userServiceUrl: 'https://$_stagingHost/api/userprofiles',
    matchmakingServiceUrl: 'https://$_stagingHost/api/matchmaking',
    photoServiceUrl: 'https://$_stagingHost/api/photos',
    messagingServiceUrl: 'https://$_stagingHost/api/messages',
    swipeServiceUrl: 'https://$_stagingHost/api/swipes',
    gatewayUrl: 'https://$_stagingHost',
    keycloakUrl: 'https://$_stagingHost/auth',
    keycloakRealm: 'DatingApp',
    keycloakClientId: 'dejtingapp-flutter',
    keycloakScopes: const ['openid', 'profile', 'email', 'offline_access'],
    keycloakRedirectUri: 'dejtingapp://callback',
    apiTimeout: const Duration(seconds: 15),
    enableLogging: true,
    enableDebugMode: true,
    databaseName: 'dating_app_staging',
  );

  // Production environment (future)
  static EnvironmentSettings get _productionSettings => EnvironmentSettings(
    name: 'Production',
    userServiceUrl: 'https://api.yourdatingapp.com/users',
    matchmakingServiceUrl: 'https://api.yourdatingapp.com/matchmaking',
    photoServiceUrl: 'https://api.yourdatingapp.com/photos',
    messagingServiceUrl:
        'https://api.yourdatingapp.com/messaging', // ADDED: Messaging service
    swipeServiceUrl: 'https://api.yourdatingapp.com/swipes',
    gatewayUrl: 'https://api.yourdatingapp.com',
    keycloakUrl: 'https://auth.yourdatingapp.com',
    keycloakRealm: 'DatingApp',
    keycloakClientId: 'dejtingapp-flutter',
    keycloakScopes: const ['openid', 'profile', 'email', 'offline_access'],
    keycloakRedirectUri: 'com.dejtingapp://oauth2redirect',
    apiTimeout: const Duration(seconds: 10),
    enableLogging: false,
    enableDebugMode: false,
    databaseName: 'dating_app_prod',
  );

  /// LAN IP of the dev machine — used when running on a real Android device.
  /// The emulator uses 10.0.2.2 (virtual router), but a physical phone needs
  /// the machine's actual network address. Update this when your IP changes.
  static const String _devMachineLanIp = '127.0.0.1';  // adb reverse tunnels all ports over USB

  /// Whether the app is running on an Android emulator vs a real device.
  /// Set once at startup by [detectEmulator].
  static bool _isRunningOnEmulator = true; // safe default for dev
  static bool get isEmulator => _isRunningOnEmulator;

  static String _getBaseUrl(int port) {
    if (kIsWeb) {
      return 'http://localhost:$port';
    }
    if (Platform.isAndroid) {
      // 10.0.2.2 is the emulator's alias for the host machine.
      // Real devices must use the host's LAN IP instead.
      return _isRunningOnEmulator
          ? 'http://10.0.2.2:$port'
          : 'http://$_devMachineLanIp:$port';
    }
    return 'http://localhost:$port';
  }

  /// Call once from main() before any network requests.
  static Future<void> detectEmulator() async {
    if (!Platform.isAndroid) {
      _isRunningOnEmulator = false;
      return;
    }
    try {
      final result = await Process.run('getprop', ['ro.build.fingerprint']);
      final fingerprint = (result.stdout as String).trim();
      _isRunningOnEmulator = fingerprint.contains('generic') ||
          fingerprint.contains('emulator') ||
          fingerprint.contains('sdk_gphone') ||
          fingerprint.contains('vbox');
      debugPrint('📱 Device: ${_isRunningOnEmulator ? "EMULATOR" : "REAL DEVICE → $_devMachineLanIp"}');
    } catch (_) {
      _isRunningOnEmulator = true;
    }
  }

}

class EnvironmentSettings {
  final String name;
  final String userServiceUrl;
  final String matchmakingServiceUrl;
  final String photoServiceUrl;
  final String messagingServiceUrl; // ADDED: Messaging service URL
  final String swipeServiceUrl;
  final String gatewayUrl;
  final String keycloakUrl;
  final String keycloakRealm;
  final String keycloakClientId;
  final List<String> keycloakScopes;
  final String keycloakRedirectUri;
  final Duration apiTimeout;
  final bool enableLogging;
  final bool enableDebugMode;
  final String databaseName;

  const EnvironmentSettings({
    required this.name,
    required this.userServiceUrl,
    required this.matchmakingServiceUrl,
    required this.photoServiceUrl,
    required this.messagingServiceUrl, // ADDED: Required parameter
    required this.swipeServiceUrl,
    required this.gatewayUrl,
    required this.keycloakUrl,
    required this.keycloakRealm,
    required this.keycloakClientId,
    required this.keycloakScopes,
    required this.keycloakRedirectUri,
    required this.apiTimeout,
    required this.enableLogging,
    required this.enableDebugMode,
    required this.databaseName,
  });

  String get keycloakIssuer => '$keycloakUrl/realms/$keycloakRealm';
  Uri get keycloakTokenEndpoint =>
      Uri.parse('$keycloakIssuer/protocol/openid-connect/token');
  Uri get keycloakUserInfoEndpoint =>
      Uri.parse('$keycloakIssuer/protocol/openid-connect/userinfo');
  Uri get keycloakLogoutEndpoint =>
      Uri.parse('$keycloakIssuer/protocol/openid-connect/logout');
  Uri get keycloakAuthEndpoint =>
      Uri.parse('$keycloakIssuer/protocol/openid-connect/auth');

  @override
  String toString() => 'Environment: $name';
}

// Convenience methods for easy environment switching
class EnvSwitcher {
  static void useDevelopment() {
    EnvironmentConfig.setEnvironment(Environment.development);
    if (kDebugMode) {
      debugPrint('🔧 Switched to DEVELOPMENT environment');
      debugPrint('Gateway: ${EnvironmentConfig.settings.gatewayUrl}');
      debugPrint('Keycloak: ${EnvironmentConfig.settings.keycloakUrl}');
    }
  }

  static void useStaging() {
    EnvironmentConfig.setEnvironment(Environment.staging);
    if (kDebugMode) {
      debugPrint('🔶 Switched to STAGING environment');
      debugPrint('Gateway: ${EnvironmentConfig.settings.gatewayUrl}');
      debugPrint('Keycloak: ${EnvironmentConfig.settings.keycloakUrl}');
    }
  }

  static void useProduction() {
    EnvironmentConfig.setEnvironment(Environment.production);
    if (kDebugMode) {
      debugPrint('🚀 Switched to PRODUCTION environment');
      debugPrint('Gateway: ${EnvironmentConfig.settings.gatewayUrl}');
      debugPrint('Keycloak: ${EnvironmentConfig.settings.keycloakUrl}');
    }
  }
}
