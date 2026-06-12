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
/// Before logging in, optionally resets all interactions (matches, swipes,
/// messages) and re-seeds mutual likes between the demo-user and active bot
/// profiles so there are fresh candidates to swipe on.
class DevAutoLogin {
  const DevAutoLogin._();

  static const _demoUsername = 'bot_demo-user@bot.local';
  static const _demoPassword = 'bot_pass_demo-user';
  static const _disableFlag = 'DEMO_AUTO_LOGIN_DISABLED';

  // Bot profile IDs (from seeding / bot state)
  static const _demoProfileId = 1;
  static const _botProfiles = [2, 3, 4]; // maja, elsa, linnea

  /// Public entry point — timeout-protected.
  static Future<void> ensureDemoSession() async {
    if (!EnvironmentConfig.isDevelopment && !EnvironmentConfig.isStaging) return;

    try {
      await _doLogin().timeout(const Duration(seconds: 60));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Dev auto-login timed out or failed: $e');
      }
    }
  }

  /// Actual login logic with optional reset + seed.
  static Future<void> _doLogin() async {
    if (!kIsWeb) {
      final env = Platform.environment;
      if (env[_disableFlag] == '1' ||
          env[_disableFlag]?.toLowerCase() == 'true') {
        if (kDebugMode) {
          debugPrint('🚫 Dev auto-login disabled via environment flag.');
        }
        return;
      }
    }

    final appState = AppState();
    await appState.initialize();

    // Only clear the session if we can't refresh the token.
    // Otherwise reuse the existing session to avoid login failures
    // when backend is temporarily unreachable.
    if (appState.hasValidAuthSession()) {
      if (kDebugMode) debugPrint('✅ Dev auto-login: existing session still valid, reusing');
      return;
    }

    try {
      if (kDebugMode) debugPrint('🔐 Dev auto-login: ROPC for $_demoUsername...');

      // ── 1. Get tokens via ROPC ──
      final tokens = await _getTokensViaROPC();
      if (tokens == null) {
        if (kDebugMode) debugPrint('⚠️ Dev auto-login: ROPC failed');
        return;
      }

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

      await appState.setOnboardingComplete();

      // ── 2. Seed matches (skip reset — data is managed by backend script) ──
      if (kDebugMode) debugPrint('🧹 Dev auto-login: login complete (match seeding managed by backend)');

      // Eagerly resolve profile ID
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

  /// Reset all interactions and seed fresh mutual matches.
  static Future<void> _resetAndSeed(String accessToken) async {
    final gw = EnvironmentConfig.settings.gatewayUrl;
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    // ── 2a. Composite admin reset ──
    try {
      final resetUrl = '$gw/api/admin/reset-interactions';
      if (kDebugMode) debugPrint('   ↳ Admin reset: POST $resetUrl');
      final resetResp = await http.post(Uri.parse(resetUrl), headers: headers).timeout(const Duration(seconds: 15));
      if (kDebugMode) debugPrint('   ↳ Admin reset: ${resetResp.statusCode} ${resetResp.body}');
    } catch (e) {
      if (kDebugMode) debugPrint('   ⚠️ Admin reset failed (non-fatal): $e');
    }

    // ── 2b. Demo-user likes bots ──
    for (final botId in _botProfiles) {
      try {
        final swipeBody = json.encode({
          'targetUserId': botId.toString(),
          'direction': 'like',
        });
        final swipeResp = await http.post(
          Uri.parse('$gw/api/swipes'),
          headers: headers,
          body: swipeBody,
        ).timeout(const Duration(seconds: 10));
        if (kDebugMode) debugPrint('   ↳ Swipe 1→$botId: ${swipeResp.statusCode}');
      } catch (e) {
        if (kDebugMode) debugPrint('   ⚠️ Swipe 1→$botId failed: $e');
      }
    }

    // ── 2c. Bots like demo-user (batch endpoint, no auth needed) ──
    for (final botId in _botProfiles) {
      try {
        final batchBody = json.encode({
          'userId': botId,
          'swipes': [
            {'targetUserId': _demoProfileId.toString(), 'isLike': true},
          ],
        });
        final batchResp = await http.post(
          Uri.parse('$gw/api/swipes/batch'),
          headers: {'Content-Type': 'application/json'},
          body: batchBody,
        ).timeout(const Duration(seconds: 10));
        if (kDebugMode) debugPrint('   ↳ Batch $botId→1: ${batchResp.statusCode}');
      } catch (e) {
        if (kDebugMode) debugPrint('   ⚠️ Batch $botId→1 failed: $e');
      }
    }
  }

  /// Get tokens using ROPC.
  static Future<Map<String, dynamic>?> _getTokensViaROPC() async {
    final settings = EnvironmentConfig.settings;
    final tokenUrl = settings.keycloakTokenEndpoint;

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
