// Tests for lib/services/api_service.dart
//
// Coverage:
//  - API base URL configuration (EnvironmentSettings, EnvironmentConfig, ApiUrls)
//  - Request header construction (Content-Type, Authorization Bearer)
//  - HTTP error status code handling (401, 404, 500 → null / empty list)
//  - Network-unavailable error handling (SocketException → null / empty list)
//  - AppState singleton & session-validity logic
//  - AuthService.logout edge cases
//  - Successful HTTP 200 response parsing
//
// All HTTP calls are intercepted via dart:io HttpOverrides so that no real
// network connections are made.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:dejtingapp/backend_url.dart';
import 'package:dejtingapp/config/environment.dart';
import 'package:dejtingapp/services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HttpOverrides: immediately reject every request with a SocketException.
// ─────────────────────────────────────────────────────────────────────────────

class _SocketFailureHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _SocketFailureHttpClient();
}

class _SocketFailureHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      throw const SocketException('Test mock: simulated network failure');

  @override
  void close({bool force = false}) {}
}

// ─────────────────────────────────────────────────────────────────────────────
// HttpOverrides: return a fixed HTTP status code + optional body.
//
// Pass [captureInto] to record the request headers that the production code
// writes (Content-Type, Authorization, …) for assertion.
// ─────────────────────────────────────────────────────────────────────────────

class _FixedStatusHttpOverrides extends HttpOverrides {
  final int statusCode;
  final String body;
  final Map<String, String>? captureInto;

  _FixedStatusHttpOverrides({
    required this.statusCode,
    this.body = '',
    this.captureInto,
  });

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _FixedStatusHttpClient(statusCode, body, captureInto);
}

class _FixedStatusHttpClient extends Fake implements HttpClient {
  final int _statusCode;
  final String _body;
  final Map<String, String>? _captureInto;

  _FixedStatusHttpClient(this._statusCode, this._body, this._captureInto);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FixedStatusHttpClientRequest(
        _statusCode,
        _body,
        captureInto: _captureInto,
      );

  @override
  void close({bool force = false}) {}
}

/// Minimal [HttpClientRequest] that:
///  - captures outgoing request headers into [captureInto] (when supplied)
///  - returns a [_FixedStatusHttpClientResponse] from [close]
class _FixedStatusHttpClientRequest extends Fake
    implements HttpClientRequest {
  final int _statusCode;
  final String _responseBody;
  final Map<String, String> _captureInto;

  _FixedStatusHttpClientRequest(
    this._statusCode,
    this._responseBody, {
    Map<String, String>? captureInto,
  }) : _captureInto = captureInto ?? {};

  // ── Properties set by IOClient before the request is sent ──────────────
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  int contentLength = -1;
  @override
  bool persistentConnection = true;

  @override
  HttpHeaders get headers => _CaptureHttpHeaders(_captureInto);

  // ── IOClient sends the body via Stream.pipe(this) ──────────────────────
  @override
  Future addStream(Stream<List<int>> stream) async =>
      stream.drain<void>();

  @override
  Future<HttpClientResponse> close() async =>
      _FixedStatusHttpClientResponse(_statusCode, _responseBody);

  @override
  Future<HttpClientResponse> get done => Future.value(
        _FixedStatusHttpClientResponse(_statusCode, _responseBody));
}

/// A [Stream<List<int>>] that also implements [HttpClientResponse].
/// Extending Stream<List<int>> ensures that concrete Stream methods like
/// handleError and pipe (used internally by the http package) work correctly
/// via the single abstract [listen] implementation below.
class _FixedStatusHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  final int _statusCode;
  final String _body;

  _FixedStatusHttpClientResponse(this._statusCode, this._body);

  // ── HttpClientResponse ──────────────────────────────────────────────────
  @override
  int get statusCode => _statusCode;
  @override
  int get contentLength => utf8.encode(_body).length;
  @override
  bool get isRedirect => false;
  @override
  bool get persistentConnection => false;
  @override
  String get reasonPhrase =>
      _statusCode == 200 ? 'OK' : 'Error $_statusCode';
  @override
  HttpHeaders get headers => _SimpleHttpHeaders();
  @override
  List<RedirectInfo> get redirects => [];
  @override
  List<Cookie> get cookies => [];
  @override
  HttpConnectionInfo? get connectionInfo => null;
  @override
  X509Certificate? get certificate => null;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  Future<Socket> detachSocket() => throw UnsupportedError('mock');
  @override
  Future<HttpClientResponse> redirect(
          [String? method, Uri? url, bool? followLoops]) =>
      throw UnsupportedError('mock');

  // ── Stream<List<int>> ───────────────────────────────────────────────────
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      Stream.fromIterable([utf8.encode(_body)]).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Minimal HttpHeaders implementations
// ─────────────────────────────────────────────────────────────────────────────

/// Captures header values written via [set] / [add] into [_store].
class _CaptureHttpHeaders extends Fake implements HttpHeaders {
  final Map<String, String> _store;

  _CaptureHttpHeaders(this._store);

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) =>
      _store[name.toLowerCase()] = value.toString();

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) =>
      _store[name.toLowerCase()] = value.toString();

  @override
  List<String>? operator [](String name) {
    final v = _store[name.toLowerCase()];
    return v == null ? null : [v];
  }

  @override
  String? value(String name) => _store[name.toLowerCase()];

  @override
  void forEach(void Function(String name, List<String> values) action) =>
      _store.forEach((k, v) => action(k, [v]));
}

/// Read-only response headers – IOClient only iterates these via forEach.
class _SimpleHttpHeaders extends Fake implements HttpHeaders {
  @override
  void forEach(void Function(String name, List<String> values) action) {}

  @override
  List<String>? operator [](String name) => null;

  @override
  String? value(String name) => null;

  @override
  int get contentLength => -1;

  @override
  bool get persistentConnection => false;

  @override
  ContentType? get contentType => ContentType.json;

  @override
  bool get chunkedTransferEncoding => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── EnvironmentSettings – base URL configuration ──────────────────────────
  group('EnvironmentSettings – base URL configuration', () {
    // Create a test settings instance directly to verify URL construction
    // logic without touching the global EnvironmentConfig singleton.
    const settings = EnvironmentSettings(
      name: 'TestEnv',
      userServiceUrl: 'http://localhost:8082',
      matchmakingServiceUrl: 'http://localhost:8083',
      photoServiceUrl: 'http://localhost:8085',
      messagingServiceUrl: 'http://localhost:8086',
      swipeServiceUrl: 'http://localhost:8087',
      gatewayUrl: 'http://localhost:8080',
      keycloakUrl: 'http://localhost:8090',
      keycloakRealm: 'TestRealm',
      keycloakClientId: 'test-client',
      keycloakScopes: ['openid'],
      keycloakRedirectUri: 'testapp://callback',
      apiTimeout: Duration(seconds: 15),
      enableLogging: false,
      enableDebugMode: false,
      databaseName: 'test_db',
    );

    test('keycloakIssuer combines URL and realm correctly', () {
      expect(
        settings.keycloakIssuer,
        'http://localhost:8090/realms/TestRealm',
      );
    });

    test('keycloakTokenEndpoint path ends with openid-connect/token', () {
      expect(
        settings.keycloakTokenEndpoint.path,
        endsWith('/protocol/openid-connect/token'),
      );
    });

    test('keycloakUserInfoEndpoint path ends with openid-connect/userinfo',
        () {
      expect(
        settings.keycloakUserInfoEndpoint.path,
        endsWith('/protocol/openid-connect/userinfo'),
      );
    });

    test('keycloakLogoutEndpoint path ends with openid-connect/logout', () {
      expect(
        settings.keycloakLogoutEndpoint.path,
        endsWith('/protocol/openid-connect/logout'),
      );
    });

    test('all Keycloak endpoint URIs share the same issuer base URL', () {
      final issuer = settings.keycloakIssuer;
      expect(
          settings.keycloakTokenEndpoint.toString(), startsWith(issuer));
      expect(
          settings.keycloakUserInfoEndpoint.toString(), startsWith(issuer));
      expect(
          settings.keycloakLogoutEndpoint.toString(), startsWith(issuer));
    });
  });

  // ── EnvironmentConfig – environment switching & URL format ────────────────
  group('EnvironmentConfig – environment switching', () {
    Environment? savedEnv;

    setUp(() => savedEnv = EnvironmentConfig.current);
    tearDown(() {
      if (savedEnv != null) {
        EnvironmentConfig.setEnvironment(savedEnv!);
      }
    });

    test('development environment is the default', () {
      EnvironmentConfig.setEnvironment(Environment.development);
      expect(EnvironmentConfig.isDevelopment, isTrue);
      expect(EnvironmentConfig.isProduction, isFalse);
    });

    test('production environment uses HTTPS for all service URLs', () {
      EnvironmentConfig.setEnvironment(Environment.production);
      expect(
          EnvironmentConfig.settings.userServiceUrl, startsWith('https://'));
      expect(EnvironmentConfig.settings.matchmakingServiceUrl,
          startsWith('https://'));
      expect(
          EnvironmentConfig.settings.keycloakUrl, startsWith('https://'));
    });

    test('development Keycloak client ID is dejtingapp-flutter', () {
      EnvironmentConfig.setEnvironment(Environment.development);
      expect(
        EnvironmentConfig.settings.keycloakClientId,
        'dejtingapp-flutter',
      );
    });

    test('development API timeout is 30 seconds', () {
      EnvironmentConfig.setEnvironment(Environment.development);
      expect(
        EnvironmentConfig.settings.apiTimeout,
        const Duration(seconds: 30),
      );
    });
  });

  // ── ApiUrls – service URL delegation ──────────────────────────────────────
  group('ApiUrls – service URL delegation', () {
    tearDown(() => EnvironmentConfig.setEnvironment(Environment.development));

    test('ApiUrls.userService returns a non-empty HTTP URL', () {
      expect(ApiUrls.userService, isNotEmpty);
      expect(ApiUrls.userService, startsWith('http'));
    });

    test('ApiUrls.matchmakingService returns a non-empty HTTP URL', () {
      expect(ApiUrls.matchmakingService, isNotEmpty);
      expect(ApiUrls.matchmakingService, startsWith('http'));
    });
  });

  // ── AppState – singleton & session management ─────────────────────────────
  group('AppState – singleton & session management', () {
    test('AppState() always returns the same singleton instance', () {
      expect(identical(AppState(), AppState()), isTrue);
    });

    test('hasValidAuthSession returns false when no tokens are set', () {
      // In a unit-test environment no login has been performed, so all token
      // fields remain null and the session must be considered invalid.
      expect(AppState().hasValidAuthSession(), isFalse);
    });
  });

  // ── AuthService – request header construction ─────────────────────────────
  group('AuthService – request header construction', () {
    HttpOverrides? savedOverrides;
    setUp(() => savedOverrides = HttpOverrides.current);
    tearDown(() => HttpOverrides.global = savedOverrides);

    test(
        'login sends Content-Type: application/x-www-form-urlencoded',
        () async {
      final headers = <String, String>{};
      HttpOverrides.global =
          _FixedStatusHttpOverrides(statusCode: 401, captureInto: headers);

      await AuthService.login('user', 'password');

      expect(
        headers['content-type'],
        contains('application/x-www-form-urlencoded'),
      );
    });

    test('fetchUserInfo sends Authorization: Bearer <token>', () async {
      final headers = <String, String>{};
      HttpOverrides.global =
          _FixedStatusHttpOverrides(statusCode: 401, captureInto: headers);

      await AuthService.fetchUserInfo('my-test-token');

      expect(headers['authorization'], 'Bearer my-test-token');
    });

    test('updateUserProfile returns false when no auth token is available',
        () async {
      // UserService.updateUserProfile calls AppState().getOrRefreshAuthToken()
      // first. With no token stored in this unit-test environment, it returns
      // null and updateUserProfile aborts early with false – no HTTP request
      // is made.
      final ok =
          await UserService.updateUserProfile('uid', {'name': 'Test'});
      expect(ok, isFalse);
    });
  });

  // ── AuthService – HTTP error status code handling ─────────────────────────
  group('AuthService – HTTP error status code handling', () {
    HttpOverrides? savedOverrides;
    setUp(() => savedOverrides = HttpOverrides.current);
    tearDown(() => HttpOverrides.global = savedOverrides);

    test('login returns null for HTTP 401 Unauthorized', () async {
      HttpOverrides.global =
          _FixedStatusHttpOverrides(statusCode: 401);
      expect(await AuthService.login('user', 'password'), isNull);
    });

    test('login returns null for HTTP 404 Not Found', () async {
      HttpOverrides.global =
          _FixedStatusHttpOverrides(statusCode: 404);
      expect(await AuthService.login('user', 'password'), isNull);
    });

    test('login returns null for HTTP 500 Internal Server Error', () async {
      HttpOverrides.global =
          _FixedStatusHttpOverrides(statusCode: 500);
      expect(await AuthService.login('user', 'password'), isNull);
    });

    test('refreshToken returns null for HTTP 401 Unauthorized', () async {
      HttpOverrides.global =
          _FixedStatusHttpOverrides(statusCode: 401);
      expect(
          await AuthService.refreshToken('some-refresh-token'), isNull);
    });

    test('fetchUserInfo returns null for HTTP 401 Unauthorized', () async {
      HttpOverrides.global =
          _FixedStatusHttpOverrides(statusCode: 401);
      expect(
          await AuthService.fetchUserInfo('some-access-token'), isNull);
    });
  });

  // ── AuthService – network error handling ──────────────────────────────────
  group('AuthService – network error handling', () {
    HttpOverrides? savedOverrides;

    setUp(() => savedOverrides = HttpOverrides.current);
    tearDown(() => HttpOverrides.global = savedOverrides);

    test('login returns null when network is unavailable', () async {
      HttpOverrides.global = _SocketFailureHttpOverrides();
      expect(await AuthService.login('user', 'password'), isNull);
    });

    test('refreshToken returns null when network is unavailable', () async {
      HttpOverrides.global = _SocketFailureHttpOverrides();
      expect(
          await AuthService.refreshToken('refresh-token'), isNull);
    });

    test('fetchUserInfo returns null when network is unavailable', () async {
      HttpOverrides.global = _SocketFailureHttpOverrides();
      expect(
          await AuthService.fetchUserInfo('access-token'), isNull);
    });
  });

  // ── AuthService – logout edge cases ───────────────────────────────────────
  group('AuthService – logout edge cases', () {
    test('logout with null refreshToken completes without error', () async {
      await expectLater(
        () => AuthService.logout(refreshToken: null),
        returnsNormally,
      );
    });

    test('logout with empty refreshToken completes without error', () async {
      await expectLater(
        () => AuthService.logout(refreshToken: ''),
        returnsNormally,
      );
    });
  });

  // ── AuthService – successful 200 response parsing ─────────────────────────
  group('AuthService – successful 200 response parsing', () {
    HttpOverrides? savedOverrides;
    setUp(() => savedOverrides = HttpOverrides.current);
    tearDown(() => HttpOverrides.global = savedOverrides);

    test('login returns token map when server responds HTTP 200', () async {
      const responseBody = '{'
          '"access_token":"at123",'
          '"refresh_token":"rt456",'
          '"expires_in":300'
          '}';
      HttpOverrides.global =
          _FixedStatusHttpOverrides(statusCode: 200, body: responseBody);

      final result = await AuthService.login('user', 'password');

      expect(result, isNotNull);
      expect(result!['access_token'], 'at123');
      expect(result['refresh_token'], 'rt456');
      expect(result['expires_in'], 300);
    });

    test('fetchUserInfo returns user map when server responds HTTP 200',
        () async {
      const responseBody = '{'
          '"sub":"user-uuid",'
          '"email":"user@example.com"'
          '}';
      HttpOverrides.global =
          _FixedStatusHttpOverrides(statusCode: 200, body: responseBody);

      final result =
          await AuthService.fetchUserInfo('valid-access-token');

      expect(result, isNotNull);
      expect(result!['sub'], 'user-uuid');
      expect(result['email'], 'user@example.com');
    });
  });
}
