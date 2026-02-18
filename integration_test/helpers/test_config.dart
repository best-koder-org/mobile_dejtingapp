
/// Test configuration with environment-based overrides
/// Use --dart-define to customize URLs for different environments
class TestConfig {
  // Base gateway URL (YARP)
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080',
  );

  // Keycloak configuration
  static const String keycloakBaseUrl = String.fromEnvironment(
    'KEYCLOAK_URL',
    defaultValue: 'http://localhost:8090',
  );

  static const String keycloakRealm = String.fromEnvironment(
    'KEYCLOAK_REALM',
    defaultValue: 'DatingApp',
  );

  static const String keycloakClientId = String.fromEnvironment(
    'KEYCLOAK_CLIENT_ID',
    defaultValue: 'dejtingapp-flutter',
  );

  static const String keycloakAdminUser = String.fromEnvironment(
    'KEY CLOAK_ADMIN',
    defaultValue: 'admin',
  );

  static const String keycloakAdminPassword = String.fromEnvironment(
    'KEYCLOAK_ADMIN_PASSWORD',
    defaultValue: 'admin',
  );

  // Service-specific URLs (for debugging YARP routing issues)
  static const String yarpUrl = String.fromEnvironment(
    'YARP_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String userServiceUrl = String.fromEnvironment(
    'USER_SERVICE_URL',
    defaultValue: 'http://localhost:8082',
  );

  static const String matchingServiceUrl = String.fromEnvironment(
    'MATCHING_SERVICE_URL',
    defaultValue: 'http://localhost:8083',
  );

  static const String swipeServiceUrl = String.fromEnvironment(
    'SWIPE_SERVICE_URL',
    defaultValue: 'http://localhost:8087',
  );

  static const String photoServiceUrl = String.fromEnvironment(
    'PHOTO_SERVICE_URL',
    defaultValue: 'http://localhost:8085',
  );

  static const String messagingServiceUrl = String.fromEnvironment(
    'MESSAGING_SERVICE_URL',
    defaultValue: 'http://localhost:8086',
  );

  // Feature flags
  static const bool testMessaging = bool.fromEnvironment(
    'TEST_MESSAGING',
    defaultValue: true,
  );

  static const bool testPhotos = bool.fromEnvironment(
    'TEST_PHOTOS',
    defaultValue: true,
  );

  static const bool testSafety = bool.fromEnvironment(
    'TEST_SAFETY',
    defaultValue: true,
  );

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration longApiTimeout = Duration(minutes: 2);

  static int _userCounter = 0;

  // Test data generators
  static String generateTestEmail() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    _userCounter++;
    return 'test_${timestamp}_$_userCounter@example.com';
  }

  static String generateTestUsername() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'testuser_${timestamp}_$_userCounter';
  }
}

/// Mutable test user object that tracks auth state across helpers
class TestUser {
  String email;
  String password;
  String username;
  
  String? userId;           // Keycloak user ID
  String? accessToken;      // JWT token
  String? refreshToken;     // Refresh token
  int? profileId;          // UserService profile ID

  TestUser({
    required this.email,
    required this.password,
    required this.username,
    this.userId,
    this.accessToken,
    this.refreshToken,
    this.profileId,
  });

  /// Factory: Create randomized test user to avoid conflicts
  factory TestUser.random() {
    return TestUser(
      email: TestConfig.generateTestEmail(),
      password: 'Test123!@#',  // Fixed password for all test users
      username: TestConfig.generateTestUsername(),
    );
  }

  /// Auth headers for authenticated requests
  Map<String, String> get authHeaders => {
    'Authorization': 'Bearer $accessToken',
  };

  /// Check if user has valid auth token
  bool get isAuthenticated => accessToken != null;

  /// Check if user has profile created
  bool get hasProfile => profileId != null;
}
