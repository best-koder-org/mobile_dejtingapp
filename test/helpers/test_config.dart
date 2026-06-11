/// Test configuration shared between test/ and integration_test/ directories.
///
/// Use --dart-define to customize URLs for different environments.
class TestConfig {
  /// Base gateway URL (YARP).
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );
}
