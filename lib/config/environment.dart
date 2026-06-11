import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Environment {
  development,
  staging,
  production,
}

/// Which dev server backend to connect to.
///
/// - [server]: LAN IP of the dev machine running Docker (192.168.1.103).
/// - [funnel]: Tailscale Funnel URL (public internet, works on emulator).
/// - [custom]: User-entered IP/hostname.
enum DevServer { server, funnel, custom, local }

class EnvironmentConfig {
  static Environment _currentEnvironment = Environment.development;
  static DevServer _devServer = DevServer.local;

  /// Custom host override for [DevServer.custom].
  static String _customHost = '';

  static Environment get current => _currentEnvironment;
  static DevServer get devServer => _devServer;
  static String get customHost => _customHost;
  static const String _prefsKey = 'dev_server_choice';
  static const String _prefsCustomHostKey = 'dev_custom_host';

  static void setEnvironment(Environment env) {
    _currentEnvironment = env;
  }

  /// Switch dev server and persist choice.
  static Future<void> setDevServer(DevServer server, {String? customHost}) async {
    _devServer = server;
    if (customHost != null) _customHost = customHost;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, server.index);
    if (customHost != null) {
      await prefs.setString(_prefsCustomHostKey, customHost);
    }
  }

  /// Load persisted dev server choice. Call once at startup.
  static Future<void> loadDevServerChoice() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_prefsKey) ?? DevServer.local.index;
    _devServer = DevServer.values[idx];
    _customHost = prefs.getString(_prefsCustomHostKey) ?? '';
  }

  // Convenience checks
  static bool get isDevelopment => _currentEnvironment == Environment.development;
  static bool get isStaging => _currentEnvironment == Environment.staging;
  static bool get isProduction => _currentEnvironment == Environment.production;

  // ── Dev server hosts ──────────────────────────────────────────────────────
  static const String _devMachineLanIp = '192.168.1.103';
  static const String _funnelHost = 'a.tail45c6a7.ts.net';

  /// The active hostname/IP for the current dev server choice.
  static String get _activeDevHost {
    switch (_devServer) {
      case DevServer.server:
        return _devMachineLanIp;
      case DevServer.funnel:
        return _funnelHost;
      case DevServer.custom:
        return _customHost.isNotEmpty ? _customHost : _devMachineLanIp;
      case DevServer.local:
        if (_isRunningOnEmulator) return '10.0.2.2';
        // Physical Android device → use dev machine LAN IP
        if (Platform.isAndroid) return _devMachineLanIp;
        return 'localhost';
    }
  }

  /// The URL scheme for the current dev server.
  static String get _activeDevScheme {
    // Funnel always uses https; LAN and custom default to http
    return _devServer == DevServer.funnel ? 'https' : 'http'; // local and server also use http
  }

  /// Human-readable label for the current dev server choice.
  static String get devServerLabel {
    switch (_devServer) {
      case DevServer.server:
        return 'Server ($_devMachineLanIp)';
      case DevServer.funnel:
        return 'Funnel ($_funnelHost)';
      case DevServer.custom:
        return 'Custom (${_customHost.isNotEmpty ? _customHost : "not set"})';
      case DevServer.local:
        return 'Local (${_isRunningOnEmulator ? "10.0.2.2" : "localhost"})';
    }
  }

  // ── Environment settings ──────────────────────────────────────────────────
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

  // ── Staging constants (dart-define) ───────────────────────────────────────
  static const String _stagingScheme = String.fromEnvironment(
    'STAGING_SCHEME',
    defaultValue: 'https',
  );
  static const String _stagingHost = String.fromEnvironment(
    'STAGING_HOST',
    defaultValue: 'CHANGE_ME.ts.net',
  );

  // ── Development settings ──────────────────────────────────────────────────
  static EnvironmentSettings get _developmentSettings => EnvironmentSettings(
    name: _devServer == DevServer.funnel ? 'Dev (Funnel)' : 'Development',
    userServiceUrl: _devUrl(8082),
    matchmakingServiceUrl: _devUrl(8083),
    photoServiceUrl: _devUrl(8085),
    messagingServiceUrl: _devUrl(8086),
    swipeServiceUrl: _devUrl(8087),
    gatewayUrl: _devUrl(8080),
    keycloakUrl: _devServer == DevServer.funnel ? 'https://$_funnelHost/auth' : _devUrl(8090), // local/server/custom all use direct Keycloak port
    keycloakRealm: 'DatingApp',
    keycloakClientId: 'dejtingapp-flutter',
    keycloakScopes: const ['openid', 'profile', 'email', 'offline_access'],
    keycloakRedirectUri: 'dejtingapp://callback',
    apiTimeout: const Duration(seconds: 30),
    enableLogging: true,
    enableDebugMode: true,
    databaseName: 'dating_app_dev',
  );

  // ── Staging settings (Tailscale Funnel) ───────────────────────────────────
  static EnvironmentSettings get _stagingSettings => EnvironmentSettings(
    name: 'Staging',
    userServiceUrl: '$_stagingScheme://$_stagingHost',
    matchmakingServiceUrl: '$_stagingScheme://$_stagingHost',
    photoServiceUrl: '$_stagingScheme://$_stagingHost',
    messagingServiceUrl: '$_stagingScheme://$_stagingHost',
    swipeServiceUrl: '$_stagingScheme://$_stagingHost',
    gatewayUrl: '$_stagingScheme://$_stagingHost',
    keycloakUrl: '$_stagingScheme://$_stagingHost/auth',
    keycloakRealm: 'DatingApp',
    keycloakClientId: 'dejtingapp-flutter',
    keycloakScopes: const ['openid', 'profile', 'email', 'offline_access'],
    keycloakRedirectUri: 'dejtingapp://callback',
    apiTimeout: const Duration(seconds: 15),
    enableLogging: true,
    enableDebugMode: true,
    databaseName: 'dating_app_staging',
  );

  // ── Production settings (future) ──────────────────────────────────────────
  static EnvironmentSettings get _productionSettings => EnvironmentSettings(
    name: 'Production',
    userServiceUrl: 'https://api.yourdatingapp.com/users',
    matchmakingServiceUrl: 'https://api.yourdatingapp.com/matchmaking',
    photoServiceUrl: 'https://api.yourdatingapp.com/photos',
    messagingServiceUrl: 'https://api.yourdatingapp.com/messaging',
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

  /// Build a dev-mode URL using the active dev host + scheme.
  static String _devUrl(int port) => '$_activeDevScheme://$_activeDevHost:$port';

  /// Whether the app is running on an Android emulator.
  static bool _isRunningOnEmulator = true;
  static bool get isEmulator => _isRunningOnEmulator;

  /// Call once from main() before any network requests.
  static Future<void> detectEmulator() async {
    if (kIsWeb) {
      _isRunningOnEmulator = false;
      return;
    }
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
      debugPrint('📱 Device: ${_isRunningOnEmulator ? "EMULATOR" : "REAL DEVICE → $_activeDevHost"}');
    } catch (_) {
      _isRunningOnEmulator = true;
    }
  }
}

// ── EnvironmentSettings ─────────────────────────────────────────────────────

class EnvironmentSettings {
  final String name;
  final String userServiceUrl;
  final String matchmakingServiceUrl;
  final String photoServiceUrl;
  final String messagingServiceUrl;
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
    required this.messagingServiceUrl,
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

// ── EnvSwitcher ─────────────────────────────────────────────────────────────

class EnvSwitcher {
  static void useDevelopment() {
    EnvironmentConfig.setEnvironment(Environment.development);
    if (kDebugMode) {
      debugPrint('🔧 Switched to DEVELOPMENT (${EnvironmentConfig.devServerLabel})');
      debugPrint('Gateway: ${EnvironmentConfig.settings.gatewayUrl}');
      debugPrint('Keycloak: ${EnvironmentConfig.settings.keycloakUrl}');
    }
  }

  static void useStaging() {
    EnvironmentConfig.setEnvironment(Environment.staging);
    if (kDebugMode) {
      debugPrint('🔶 Switched to STAGING');
      debugPrint('Gateway: ${EnvironmentConfig.settings.gatewayUrl}');
      debugPrint('Keycloak: ${EnvironmentConfig.settings.keycloakUrl}');
    }
  }

  static void useProduction() {
    EnvironmentConfig.setEnvironment(Environment.production);
    if (kDebugMode) {
      debugPrint('🚀 Switched to PRODUCTION');
      debugPrint('Gateway: ${EnvironmentConfig.settings.gatewayUrl}');
      debugPrint('Keycloak: ${EnvironmentConfig.settings.keycloakUrl}');
    }
  }

  /// Switch dev server (LAN server / Funnel / custom) without changing env.
  static Future<void> switchDevServer(DevServer server, {String? customHost}) async {
    await EnvironmentConfig.setDevServer(server, customHost: customHost);
    // Re-apply current env so URLs recalculate
    useDevelopment();
  }
}
