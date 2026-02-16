import 'package:flutter/foundation.dart';

import '../utils/jwt_utils.dart';
import 'api_service.dart';
import 'auth_service_pkce.dart';
import 'firebase_phone_auth_service.dart';
import 'keycloak_token_exchange_service.dart';

class AuthSessionResult {
  final bool success;
  final String? message;

  const AuthSessionResult({required this.success, this.message});

  factory AuthSessionResult.ok() => const AuthSessionResult(success: true);

  factory AuthSessionResult.failure(String message) =>
      AuthSessionResult(success: false, message: message);
}

class AuthSessionManager {
  const AuthSessionManager._();

  static Future<AuthSessionResult> login({
    required String username,
    required String password,
  }) async {
    try {
      final tokenResponse = await AuthService.login(username, password);
      if (tokenResponse == null) {
        return AuthSessionResult.failure('Invalid username or password');
      }

      final accessToken = tokenResponse['access_token'] as String?;
      final refreshToken = tokenResponse['refresh_token'] as String?;
      if (accessToken == null || refreshToken == null) {
        return AuthSessionResult.failure('Authentication token missing');
      }

      final idToken = tokenResponse['id_token'] as String?;
      final expiresIn = _readInt(tokenResponse['expires_in']) ?? 300;
      final refreshExpiresIn = _readInt(tokenResponse['refresh_expires_in']);

      final accessExpiresAt =
          DateTime.now().toUtc().add(Duration(seconds: expiresIn));
      final refreshExpiresAt = refreshExpiresIn != null
          ? DateTime.now().toUtc().add(Duration(seconds: refreshExpiresIn))
          : null;

      final tokenPayload = JwtUtils.decodePayload(accessToken) ?? {};
      final userInfo = await AuthService.fetchUserInfo(accessToken) ?? {};

      final profile = _normalizeProfile(
        tokenPayload: tokenPayload,
        userInfo: userInfo,
        fallbackUsername: username,
      );

      final userId = (profile['sub'] ??
              tokenPayload['sub'] ??
              profile['preferred_username'] ??
              username)
          .toString();

      await AppState().login(
        userId: userId,
        accessToken: accessToken,
        accessTokenExpiresAt: accessExpiresAt,
        refreshToken: refreshToken,
        refreshTokenExpiresAt: refreshExpiresAt,
        idToken: idToken,
        profile: profile,
      );

      return AuthSessionResult.ok();
    } catch (e, stack) {
      debugPrint('AuthSessionManager.login failed: $e');
      debugPrint('$stack');
      return AuthSessionResult.failure('Login failed. Please try again.');
    }
  }

  static Map<String, dynamic> _normalizeProfile({
    required Map<String, dynamic> tokenPayload,
    required Map<String, dynamic> userInfo,
    required String fallbackUsername,
  }) {
    final merged = <String, dynamic>{}
      ..addAll(tokenPayload)
      ..addAll(userInfo);

    final profile = <String, dynamic>{};

    void assignIfPresent(String key) {
      if (merged.containsKey(key) && merged[key] != null) {
        profile[key] = merged[key];
      }
    }

    assignIfPresent('sub');
    assignIfPresent('email');
    assignIfPresent('preferred_username');
    assignIfPresent('given_name');
    assignIfPresent('family_name');
    assignIfPresent('name');
    assignIfPresent('locale');
    assignIfPresent('realm_access');
    assignIfPresent('resource_access');

    profile['preferred_username'] ??= fallbackUsername;
    profile['name'] ??=
        _displayNameFromIdentifier(profile['preferred_username'] as String);
    profile['email'] ??= profile['preferred_username'];
    profile['sub'] ??= profile['preferred_username'];
    profile['id'] = profile['sub'];

    if (!profile.containsKey('roles')) {
      final realmAccess = merged['realm_access'];
      if (realmAccess is Map<String, dynamic>) {
        profile['roles'] = realmAccess['roles'] ?? const <String>[];
      }
    }

    return profile;
  }

  static String _displayNameFromIdentifier(String identifier) {
    final sanitized =
        identifier.contains('@') ? identifier.split('@').first : identifier;
    final segments = sanitized.split(RegExp('[._-]'));
    return segments
        .where((segment) => segment.isNotEmpty)
        .map(
          (segment) => segment[0].toUpperCase() + segment.substring(1),
        )
        .join(' ')
        .trim();
  }

  static int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /// PKCE Authorization Code login — opens browser, no password in app.
  static Future<AuthSessionResult> loginWithPKCE() async {
    try {
      final tokenResponse = await AuthServicePkce.login();
      if (tokenResponse == null) {
        return AuthSessionResult.failure('Login cancelled or failed');
      }

      final accessToken = tokenResponse['access_token'] as String?;
      final refreshToken = tokenResponse['refresh_token'] as String?;
      if (accessToken == null || refreshToken == null) {
        return AuthSessionResult.failure('Authentication token missing');
      }

      final idToken = tokenResponse['id_token'] as String?;

      // expires_in may be int or Duration-computed int
      final dynamic rawExpiresIn = tokenResponse['expires_in'];
      final int expiresIn;
      if (rawExpiresIn is int) {
        expiresIn = rawExpiresIn > 0 ? rawExpiresIn : 300;
      } else {
        expiresIn = 300;
      }

      final accessExpiresAt =
          DateTime.now().toUtc().add(Duration(seconds: expiresIn));

      final tokenPayload = JwtUtils.decodePayload(accessToken) ?? {};
      final userInfo = await AuthService.fetchUserInfo(accessToken) ?? {};

      final profile = _normalizeProfile(
        tokenPayload: tokenPayload,
        userInfo: userInfo,
        fallbackUsername: tokenPayload['preferred_username']?.toString() ?? 'user',
      );

      final userId = (profile['sub'] ??
              tokenPayload['sub'] ??
              profile['preferred_username'] ??
              'unknown')
          .toString();

      await AppState().login(
        userId: userId,
        accessToken: accessToken,
        accessTokenExpiresAt: accessExpiresAt,
        refreshToken: refreshToken,
        idToken: idToken,
        profile: profile,
      );

      return AuthSessionResult.ok();
    } catch (e, stack) {
      debugPrint('AuthSessionManager.loginWithPKCE failed: $e');
      debugPrint('$stack');
      return AuthSessionResult.failure('Login failed. Please try again.');
    }
  }



  /// Phone OTP login — Firebase verifies phone, Keycloak issues JWT.
  /// Called after Firebase phone verification succeeds.
  ///
  /// [firebaseIdToken] The Firebase ID token from successful phone auth.
  static Future<AuthSessionResult> loginWithPhone(String firebaseIdToken) async {
    try {
      // Exchange Firebase token for Keycloak tokens
      final tokenResponse =
          await KeycloakTokenExchangeService.exchangeFirebaseToken(firebaseIdToken);
      if (tokenResponse == null) {
        return AuthSessionResult.failure(
          'Could not complete phone login. Please try again.',
        );
      }

      final accessToken = tokenResponse['access_token'] as String?;
      final refreshToken = tokenResponse['refresh_token'] as String?;
      if (accessToken == null || refreshToken == null) {
        return AuthSessionResult.failure('Authentication token missing');
      }

      final idToken = tokenResponse['id_token'] as String?;
      final expiresIn = _readInt(tokenResponse['expires_in']) ?? 300;
      final refreshExpiresIn = _readInt(tokenResponse['refresh_expires_in']);

      final accessExpiresAt =
          DateTime.now().toUtc().add(Duration(seconds: expiresIn));
      final refreshExpiresAt = refreshExpiresIn != null
          ? DateTime.now().toUtc().add(Duration(seconds: refreshExpiresIn))
          : null;

      final tokenPayload = JwtUtils.decodePayload(accessToken) ?? {};
      final userInfo = await AuthService.fetchUserInfo(accessToken) ?? {};

      // Use phone number as fallback username
      final phoneNumber = FirebasePhoneAuthService.getCurrentPhoneNumber() ?? 'phone_user';

      final profile = _normalizeProfile(
        tokenPayload: tokenPayload,
        userInfo: userInfo,
        fallbackUsername: phoneNumber,
      );

      final userId = (profile['sub'] ??
              tokenPayload['sub'] ??
              profile['preferred_username'] ??
              'unknown')
          .toString();

      await AppState().login(
        userId: userId,
        accessToken: accessToken,
        accessTokenExpiresAt: accessExpiresAt,
        refreshToken: refreshToken,
        refreshTokenExpiresAt: refreshExpiresAt,
        idToken: idToken,
        profile: profile,
      );

      return AuthSessionResult.ok();
    } catch (e, stack) {
      debugPrint('AuthSessionManager.loginWithPhone failed: $e');
      debugPrint('$stack');
      return AuthSessionResult.failure('Phone login failed. Please try again.');
    }
  }

}
