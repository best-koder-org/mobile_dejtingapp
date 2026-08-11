import 'config/environment.dart';

// Service-specific URLs using environment configuration.
//
// ⚠️ ALL services route through the YARP gateway (port 8080) for stability.
//    Direct service ports may bind to 127.0.0.1 and be unreachable from
//    a physical device on the same network. YARP binds to 0.0.0.0 and
//    proxies all /api/* paths to the correct backend service.
class ApiUrls {
  static String get userService => EnvironmentConfig.settings.gatewayUrl;
  static String get matchmakingService =>
      EnvironmentConfig.settings.gatewayUrl;
  static String get photoService => EnvironmentConfig.settings.gatewayUrl;
  static String get messagingService =>
      EnvironmentConfig.settings.gatewayUrl;
  static String get swipeService => EnvironmentConfig.settings.gatewayUrl;
  static String get gateway => EnvironmentConfig.settings.gatewayUrl;
}

// Backward compatibility for existing code that still pulls raw port numbers.
@Deprecated('Use ApiUrls from EnvironmentConfig.settings instead.')
class BackendConfig {
  static int get userPort => 8082;
  static int get matchmakingPort => 8083;
  static int get photoPort => 8085;
  static int get messagingPort => 8086;
  static int get swipePort => 8087;
  static int get gatewayPort => 8080;
  static int get yarpPort => gatewayPort;
}
