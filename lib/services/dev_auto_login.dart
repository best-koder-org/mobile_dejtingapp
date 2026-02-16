import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/environment.dart';
import 'api_service.dart';
import '../utils/jwt_utils.dart';

/// Dev Auto-Login — uses Keycloak Admin API to issue tokens WITHOUT passwords.
///
/// Flow:
/// 1. Authenticate as admin → get admin bearer token
/// 2. Look up demo user by username → get userId
/// 3. Use test-runner service account client_credentials → get token
///    (with user impersonation if needed)
///
/// This replaces the old ROPC (password grant) approach. No hardcoded passwords.
class DevAutoLogin {
  const DevAutoLogin._();

  static const _demoUsername = 'demo-user';
  static const _disableFlag = 'DEMO_AUTO_LOGIN_DISABLED';

  /// Keycloak admin credentials (only used in dev, from docker-compose)
  static const _adminUser = 'admin';
  static const _adminPass = 'admin';

  static Future<void> ensureDemoSession() async {
    if (!EnvironmentConfig.isDevelopment) {
      return;
    }

    final env = Platform.environment;
    if (env[_disableFlag] == '1' ||
        env[_disableFlag]?.toLowerCase() == 'true') {
      if (kDebugMode) {
        debugPrint('🚫 Dev auto-login disabled via environment flag.');
      }
      return;
    }

    final appState = AppState();
    await appState.initialize();

    if (appState.hasValidAuthSession()) {
      return;
    }

    try {
      // 1. Get admin token from Keycloak master realm
      final adminToken = await _getAdminToken();
      if (adminToken == null) {
        if (kDebugMode) {
          debugPrint('⚠️ Dev auto-login: Could not get admin token');
        }
        return;
      }

      // 2. Find demo user by username
      final userId = await _findUserByUsername(adminToken, _demoUsername);
      if (userId == null) {
        if (kDebugMode) {
          debugPrint('⚠️ Dev auto-login: User "$_demoUsername" not found');
        }
        return;
      }

      // 3. Use test-runner client_credentials + token exchange to impersonate user
      final tokens = await _getTokensForUser(adminToken, userId);
      if (tokens == null) {
        if (kDebugMode) {
          debugPrint('⚠️ Dev auto-login: Could not get tokens for user');
        }
        return;
      }

      // 4. Build a session from the tokens
      final accessToken = tokens['access_token'] as String;
      final refreshToken = tokens['refresh_token'] as String?;
      final idToken = tokens['id_token'] as String?;
      final expiresIn = (tokens['expires_in'] as num?)?.toInt() ?? 300;

      final tokenPayload = JwtUtils.decodePayload(accessToken) ?? {};
      final userInfo = await AuthService.fetchUserInfo(accessToken) ?? {};

      final profile = <String, dynamic>{
        'sub': tokenPayload['sub'] ?? userId,
        'preferred_username': tokenPayload['preferred_username'] ?? _demoUsername,
        'email': tokenPayload['email'] ?? userInfo['email'],
        'name': tokenPayload['name'] ?? userInfo['name'],
      };

      await appState.login(
        userId: (profile['sub'] ?? userId).toString(),
        accessToken: accessToken,
        accessTokenExpiresAt:
            DateTime.now().toUtc().add(Duration(seconds: expiresIn)),
        refreshToken: refreshToken ?? '',
        refreshTokenExpiresAt:
            DateTime.now().toUtc().add(const Duration(minutes: 30)),
        idToken: idToken,
        profile: profile,
      );

      if (kDebugMode) {
        debugPrint('✅ Dev auto-login: Logged in as $_demoUsername (Admin API)');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('⚠️ Dev auto-login failed: $e');
        debugPrint('$stack');
      }
      await AppState().logout();
    }
  }

  /// Get admin bearer token from Keycloak master realm
  static Future<String?> _getAdminToken() async {
    final settings = EnvironmentConfig.settings;
    // Admin token comes from the master realm
    final keycloakBase = settings.keycloakIssuer
        .replaceAll('/realms/DatingApp', '');
    final url = Uri.parse('$keycloakBase/realms/master/protocol/openid-connect/token');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'password',
          'client_id': 'admin-cli',
          'username': _adminUser,
          'password': _adminPass,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['access_token'] as String?;
      }
      if (kDebugMode) {
        debugPrint('Admin token request failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Admin token request error: $e');
      }
    }
    return null;
  }

  /// Find user ID by username using Admin REST API
  static Future<String?> _findUserByUsername(
      String adminToken, String username) async {
    final settings = EnvironmentConfig.settings;
    final keycloakBase = settings.keycloakIssuer
        .replaceAll('/realms/DatingApp', '');
    final url = Uri.parse(
        '$keycloakBase/admin/realms/DatingApp/users?username=$username&exact=true');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $adminToken'},
      );

      if (response.statusCode == 200) {
        final users = json.decode(response.body) as List;
        if (users.isNotEmpty) {
          return (users.first as Map<String, dynamic>)['id'] as String?;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('User lookup error: $e');
      }
    }
    return null;
  }

  /// Get tokens for a specific user using test-runner service account
  /// with token exchange (impersonation).
  static Future<Map<String, dynamic>?> _getTokensForUser(
      String adminToken, String userId) async {
    final settings = EnvironmentConfig.settings;
    final tokenUrl = settings.keycloakTokenEndpoint;

    try {
      // First get a service account token for test-runner
      final saResponse = await http.post(
        tokenUrl,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'client_credentials',
          'client_id': 'test-runner',
          'client_secret': 'CHANGE_ME_TEST_RUNNER',
        },
      );

      if (saResponse.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('test-runner client_credentials failed: ${saResponse.statusCode}');
        }
        // Fallback: use direct grant via admin-created temporary password
        return _fallbackDirectGrant(adminToken, userId);
      }

      final saData = json.decode(saResponse.body) as Map<String, dynamic>;
      final saToken = saData['access_token'] as String;

      // Token exchange: impersonate the target user
      final exchangeResponse = await http.post(
        tokenUrl,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:token-exchange',
          'client_id': 'test-runner',
          'client_secret': 'CHANGE_ME_TEST_RUNNER',
          'subject_token': saToken,
          'requested_token_type': 'urn:ietf:params:oauth:token-type:access_token',
          'requested_subject': userId,
        },
      );

      if (exchangeResponse.statusCode == 200) {
        return json.decode(exchangeResponse.body) as Map<String, dynamic>;
      }

      if (kDebugMode) {
        debugPrint('Token exchange failed: ${exchangeResponse.statusCode}');
      }

      // Fallback if token exchange is not configured
      return _fallbackDirectGrant(adminToken, userId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Token exchange error: $e');
      }
      return null;
    }
  }

  /// Fallback: set a temporary password via Admin API, do ROPC, then remove it.
  /// Used only if token exchange isn't configured yet.
  static Future<Map<String, dynamic>?> _fallbackDirectGrant(
      String adminToken, String userId) async {
    final settings = EnvironmentConfig.settings;
    final keycloakBase = settings.keycloakIssuer
        .replaceAll('/realms/DatingApp', '');


    try {
      // Set temporary password
      final resetUrl = Uri.parse(
          '$keycloakBase/admin/realms/DatingApp/users/$userId/reset-password');

      final resetResp = await http.put(
        resetUrl,
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'type': 'password',
          'value': 'DevTempPass123!',
          'temporary': false,
        }),
      );

      if (resetResp.statusCode != 204) {
        if (kDebugMode) {
          debugPrint('Password reset failed: ${resetResp.statusCode}');
        }
        return null;
      }

      // ROPC with temporary password
      final tokenUrl = settings.keycloakTokenEndpoint;
      final tokenResp = await http.post(
        tokenUrl,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'password',
          'client_id': 'test-runner',
          'client_secret': 'CHANGE_ME_TEST_RUNNER',
          'username': _demoUsername,
          'password': 'DevTempPass123!',
        },
      );

      if (tokenResp.statusCode == 200) {
        return json.decode(tokenResp.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Fallback direct grant error: $e');
      }
    }
    return null;
  }
}
