import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/environment.dart';
import 'api_service.dart';
import '../utils/jwt_utils.dart';

/// Dev Auto-Login — direct ROPC with known BotService password.
///
/// The demo-user is provisioned by BotService with a known password
/// (bot_pass_demo-user), so we just do a direct ROPC grant.
/// No admin API needed.
///
/// Wrapped with a 10-second timeout so it never blocks app startup.
class DevAutoLogin {
  const DevAutoLogin._();

  static const _demoUsername = 'bot_demo-user@bot.local';
  /// Password matches BotService's KeycloakBotProvisioner password scheme:
  /// {BOT_PASSWORD_PREFIX}{personaId} = "bot_pass_demo-user"
  static const _demoPassword = 'bot_pass_demo-user';
  static const _disableFlag = 'DEMO_AUTO_LOGIN_DISABLED';

  /// Public entry point — timeout-protected.
  static Future<void> ensureDemoSession() async {
    if (!EnvironmentConfig.isDevelopment && !EnvironmentConfig.isStaging) return;

    try {
      await _doLogin().timeout(const Duration(seconds: 30));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Dev auto-login timed out or failed: $e');
      }
    }
  }

  /// Actual login logic.
  static Future<void> _doLogin() async {
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
      if (kDebugMode) debugPrint('✅ Dev auto-login: existing session still valid');
      return;
    }

    try {
      if (kDebugMode) debugPrint('🔐 Dev auto-login: ROPC for $_demoUsername...');

      // Direct ROPC — demo-user password is set by BotService
      final tokens = await _getTokensViaROPC();
      if (tokens == null) {
        if (kDebugMode) debugPrint('⚠️ Dev auto-login: ROPC failed (is BotService running?)');
        return;
      }

      // Build session
      final accessToken = tokens['access_token'] as String;
      final refreshToken = tokens['refresh_token'] as String?;
      final idToken = tokens['id_token'] as String?;
      final expiresIn = (tokens['expires_in'] as num?)?.toInt() ?? 300;

      final tokenPayload = JwtUtils.decodePayload(accessToken) ?? {};
      final userInfo = await AuthService.fetchUserInfo(accessToken) ?? {};

      final userId = (tokenPayload['sub'] ?? '').toString();
      final profile = <String, dynamic>{
        'sub': userId,
        'preferred_username': tokenPayload['preferred_username'] ?? _demoUsername,
        'email': tokenPayload['email'] ?? userInfo['email'],
        'name': tokenPayload['name'] ?? userInfo['name'],
      };

      await appState.login(
        userId: userId,
        accessToken: accessToken,
        accessTokenExpiresAt: DateTime.now().toUtc().add(Duration(seconds: expiresIn)),
        refreshToken: refreshToken ?? '',
        refreshTokenExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 30)),
        idToken: idToken,
        profile: profile,
      );

      // Demo user is already onboarded on the backend
      await appState.setOnboardingComplete();

      // Eagerly resolve the integer profile ID so matchmaking works
      final profileId = await appState.getOrResolveProfileId();
      if (kDebugMode) {
        debugPrint('✅ Dev auto-login: Logged in as $_demoUsername ($userId), profileId=$profileId');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('⚠️ Dev auto-login failed: $e');
        debugPrint('$stack');
      }
      await AppState().logout();
    }
  }

  /// Get tokens using direct grant (ROPC) with the BotService-provisioned password.
  static Future<Map<String, dynamic>?> _getTokensViaROPC() async {
    final settings = EnvironmentConfig.settings;
    final tokenUrl = settings.keycloakTokenEndpoint;
    if (kDebugMode) debugPrint('🔗 ROPC token URL: $tokenUrl');

    final sw = Stopwatch()..start();
    final tokenResp = await http.post(
      tokenUrl,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'password',
        'client_id': settings.keycloakClientId,
        'username': _demoUsername,
        'password': _demoPassword,
        'scope': 'openid profile email',
      },
    );

    if (kDebugMode) debugPrint('⏱️ ROPC HTTP took ${sw.elapsedMilliseconds}ms, status=${tokenResp.statusCode}');
    if (tokenResp.statusCode == 200) {
      return json.decode(tokenResp.body) as Map<String, dynamic>;
    }

    if (kDebugMode) {
      debugPrint('ROPC failed: ${tokenResp.statusCode} ${tokenResp.body}');
    }
    return null;
  }
}
