import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:dejtingapp/services/swipe_service.dart';

/// Unit tests for SwipeService.
///
/// Uses [MockClient] from package:http/testing.dart to intercept HTTP calls
/// without a live server. Authentication is short-circuited via the optional
/// [tokenProvider] parameter so tests are completely self-contained.
void main() {
  group('SwipeService.swipe', () {
    test('returns null when tokenProvider returns null', () async {
      final result = await SwipeService.swipe(
        targetUserId: 'user-123',
        direction: SwipeDirection.like,
        tokenProvider: () async => null,
      );

      expect(result, isNull);
    });

    test('like swipe returns response body on 200 with no match', () async {
      final responseBody = {
        'swipeId': 'sw-001',
        'direction': 'like',
        'match': false,
      };

      final client = MockClient((request) async {
        return http.Response(json.encode(responseBody), 200);
      });

      final result = await SwipeService.swipe(
        targetUserId: 'user-456',
        direction: SwipeDirection.like,
        client: client,
        tokenProvider: () async => 'test-token',
      );

      expect(result, isNotNull);
      expect(result!['match'], isFalse);
      expect(result['direction'], equals('like'));
    });

    test('like swipe returns match-detected response on 200', () async {
      final responseBody = {
        'swipeId': 'sw-002',
        'direction': 'like',
        'match': true,
        'matchId': 'match-999',
      };

      final client = MockClient((request) async {
        return http.Response(json.encode(responseBody), 200);
      });

      final result = await SwipeService.swipe(
        targetUserId: 'user-789',
        direction: SwipeDirection.like,
        client: client,
        tokenProvider: () async => 'test-token',
      );

      expect(result, isNotNull);
      expect(result!['match'], isTrue);
      expect(result['matchId'], equals('match-999'));
    });

    test('pass swipe sends correct direction in request body', () async {
      String? capturedDirection;

      final client = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, dynamic>;
        capturedDirection = body['direction'] as String?;
        return http.Response(
          json.encode({'swipeId': 'sw-003', 'match': false}),
          200,
        );
      });

      final result = await SwipeService.swipe(
        targetUserId: 'user-pass',
        direction: SwipeDirection.pass,
        client: client,
        tokenProvider: () async => 'test-token',
      );

      expect(result, isNotNull);
      expect(capturedDirection, equals('pass'));
    });

    test('superlike swipe sends correct direction in request body', () async {
      String? capturedDirection;

      final client = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, dynamic>;
        capturedDirection = body['direction'] as String?;
        return http.Response(
          json.encode({'swipeId': 'sw-004', 'match': false}),
          200,
        );
      });

      final result = await SwipeService.swipe(
        targetUserId: 'user-super',
        direction: SwipeDirection.superlike,
        client: client,
        tokenProvider: () async => 'test-token',
      );

      expect(result, isNotNull);
      expect(capturedDirection, equals('superlike'));
    });

    test('returns null immediately on 4xx client error (no retry)', () async {
      int callCount = 0;

      final client = MockClient((request) async {
        callCount++;
        return http.Response('Unauthorized', 401);
      });

      final result = await SwipeService.swipe(
        targetUserId: 'user-err',
        direction: SwipeDirection.like,
        client: client,
        tokenProvider: () async => 'test-token',
      );

      expect(result, isNull);
      // 4xx errors must not be retried
      expect(callCount, equals(1));
    });

    test('returns null after exhausting retries on 5xx server error', () async {
      int callCount = 0;

      final client = MockClient((request) async {
        callCount++;
        return http.Response('Internal Server Error', 500);
      });

      final result = await SwipeService.swipe(
        targetUserId: 'user-5xx',
        direction: SwipeDirection.like,
        client: client,
        tokenProvider: () async => 'test-token',
        // Use a fixed idempotency key so retries share the same key
        idempotencyKey: 'idem-key-retry',
      );

      expect(result, isNull);
      // Must have attempted _maxRetries times
      expect(callCount, equals(3));
    });

    test('request includes Authorization header and targetUserId', () async {
      String? authHeader;
      String? targetId;

      final client = MockClient((request) async {
        authHeader = request.headers['Authorization'];
        final body = json.decode(request.body) as Map<String, dynamic>;
        targetId = body['targetUserId'] as String?;
        return http.Response(
          json.encode({'swipeId': 'sw-005', 'match': false}),
          200,
        );
      });

      await SwipeService.swipe(
        targetUserId: 'target-user-007',
        direction: SwipeDirection.like,
        client: client,
        tokenProvider: () async => 'bearer-token-xyz',
      );

      expect(authHeader, equals('Bearer bearer-token-xyz'));
      expect(targetId, equals('target-user-007'));
    });
  });

  group('SwipeService.batchSwipe', () {
    test('returns null when tokenProvider returns null', () async {
      final result = await SwipeService.batchSwipe(
        swipes: [
          {'targetUserId': 'user-a', 'direction': 'like'},
        ],
        tokenProvider: () async => null,
      );

      expect(result, isNull);
    });

    test('returns parsed response on successful 200 batch call', () async {
      final responseBody = {
        'processed': 2,
        'results': [
          {'targetUserId': 'user-a', 'match': false},
          {'targetUserId': 'user-b', 'match': true, 'matchId': 'match-42'},
        ],
      };

      final client = MockClient((request) async {
        return http.Response(json.encode(responseBody), 200);
      });

      final result = await SwipeService.batchSwipe(
        swipes: [
          {'targetUserId': 'user-a', 'direction': 'like'},
          {'targetUserId': 'user-b', 'direction': 'like'},
        ],
        client: client,
        tokenProvider: () async => 'test-token',
      );

      expect(result, isNotNull);
      expect(result!['processed'], equals(2));
      final results = result['results'] as List<dynamic>;
      expect(results.length, equals(2));
    });

    test('adds idempotencyKey to each swipe that is missing one', () async {
      List<dynamic>? capturedSwipes;

      final client = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, dynamic>;
        capturedSwipes = body['swipes'] as List<dynamic>?;
        return http.Response(json.encode({'processed': 1}), 200);
      });

      await SwipeService.batchSwipe(
        swipes: [
          {'targetUserId': 'user-c', 'direction': 'pass'},
        ],
        client: client,
        tokenProvider: () async => 'test-token',
      );

      expect(capturedSwipes, isNotNull);
      expect(capturedSwipes!.length, equals(1));
      final swipe = capturedSwipes!.first as Map<String, dynamic>;
      // An idempotency key must have been auto-generated
      expect(swipe['idempotencyKey'], isNotNull);
      expect((swipe['idempotencyKey'] as String).isNotEmpty, isTrue);
    });

    test('returns null on non-200 batch response', () async {
      final client = MockClient((request) async {
        return http.Response('Bad Request', 400);
      });

      final result = await SwipeService.batchSwipe(
        swipes: [
          {'targetUserId': 'user-d', 'direction': 'like'},
        ],
        client: client,
        tokenProvider: () async => 'test-token',
      );

      expect(result, isNull);
    });
  });
}
