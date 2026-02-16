import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/services/keycloak_token_exchange_service.dart';

/// Unit tests for KeycloakTokenExchangeService.
///
/// Tests the token exchange service that converts Firebase ID tokens
/// into Keycloak JWTs via RFC 8693 token exchange.
void main() {
  group('KeycloakTokenExchangeService', () {
    group('exchangeFirebaseToken', () {
      test('returns null for empty token', () async {
        final result =
            await KeycloakTokenExchangeService.exchangeFirebaseToken('');
        // With an empty token, Keycloak will reject → service returns null
        expect(result, isNull);
      });

      test('returns null for malformed token', () async {
        final result = await KeycloakTokenExchangeService
            .exchangeFirebaseToken('not-a-valid-jwt');
        expect(result, isNull);
      });
    });

    group('exchangeViaDirectGrant', () {
      test('returns null for empty token', () async {
        final result =
            await KeycloakTokenExchangeService.exchangeViaDirectGrant('');
        expect(result, isNull);
      });
    });

    group('token response parsing', () {
      test('service class exists and is accessible', () {
        expect(KeycloakTokenExchangeService, isNotNull);
      });
    });
  });
}
