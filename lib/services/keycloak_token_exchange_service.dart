import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/environment.dart';

/// Keycloak Token Exchange Service
///
/// Exchanges a Firebase ID token for a Keycloak access token using
/// OAuth 2.0 Token Exchange (RFC 8693) or the IDP-brokered token endpoint.
///
/// Flow:
///   1. User verifies phone via Firebase → gets Firebase ID Token
///   2. This service POSTs the Firebase token to Keycloak's token endpoint
///   3. Keycloak validates the Firebase token against the Firebase IDP
///   4. Keycloak issues its own JWT (access + refresh tokens)
///   5. All backend services continue to validate Keycloak JWTs (unchanged)
///
/// Architecture Layer: Infrastructure → Auth Gateway
class KeycloakTokenExchangeService {
  static EnvironmentSettings get _env => EnvironmentConfig.settings;

  /// Exchange a Firebase ID token for Keycloak tokens.
  ///
  /// Uses the OAuth2 token exchange grant type with the Firebase IDP alias.
  /// Keycloak must have Firebase configured as an OIDC Identity Provider
  /// with alias "firebase".
  ///
  /// Returns a map with: access_token, refresh_token, id_token, expires_in
  /// or null on failure.
  static Future<Map<String, dynamic>?> exchangeFirebaseToken(
    String firebaseIdToken,
  ) async {
    try {
      final response = await http.post(
        _env.keycloakTokenEndpoint,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:token-exchange',
          'client_id': _env.keycloakClientId,
          'subject_token': firebaseIdToken,
          'subject_token_type': 'urn:ietf:params:oauth:token-type:jwt',
          'subject_issuer': 'firebase', // Keycloak IDP alias
          'requested_token_type': 'urn:ietf:params:oauth:token-type:access_token',
          'scope': _env.keycloakScopes.join(' '),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        debugPrint('🔄 Token exchange successful');
        return data;
      }

      debugPrint(
        '❌ Token exchange failed (${response.statusCode}): ${response.body}',
      );
      return null;
    } catch (e, stack) {
      debugPrint('Token exchange error: $e');
      debugPrint('$stack');
      return null;
    }
  }

  /// Alternative: Direct IDP-brokered login for scenarios where
  /// standard token exchange isn't available.
  ///
  /// Posts the Firebase token to a custom Keycloak endpoint that
  /// validates and creates sessions.
  static Future<Map<String, dynamic>?> exchangeViaDirectGrant(
    String firebaseIdToken,
  ) async {
    try {
      // This uses the direct grant flow with a custom authenticator
      // that accepts Firebase tokens instead of passwords.
      final response = await http.post(
        _env.keycloakTokenEndpoint,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'password',
          'client_id': _env.keycloakClientId,
          'username': '', // Not needed — Firebase token carries identity
          'password': '', // Not needed
          'scope': _env.keycloakScopes.join(' '),
          // Custom parameter recognized by the Keycloak Firebase authenticator
          'firebase_token': firebaseIdToken,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        debugPrint('🔄 Direct grant exchange successful');
        return data;
      }

      debugPrint(
        '❌ Direct grant exchange failed (${response.statusCode}): ${response.body}',
      );
      return null;
    } catch (e, stack) {
      debugPrint('Direct grant exchange error: $e');
      debugPrint('$stack');
      return null;
    }
  }
}
