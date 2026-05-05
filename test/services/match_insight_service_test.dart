// Tests for lib/services/match_insight_service.dart
//
// Coverage:
//  - Success path: 200 response is parsed into MatchInsight
//  - 404 response returns null (insight not yet generated)
//  - Non-2xx, non-404 response throws ApiException
//  - Cache hit avoids a second HTTP request
//  - TTL expiry triggers a refetch

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:dejtingapp/models/match_insight.dart';
import 'package:dejtingapp/services/match_insight_service.dart';

void main() {
  Map<String, dynamic> insightJson({int matchId = 42}) => {
        'matchId': matchId,
        'overallScore': 0.87,
        'reasons': ['shared interests', 'similar values'],
        'friction': ['different schedules'],
        'growth': ['travel together', 'learn new skills'],
      };

  group('MatchInsightService.fetchInsight', () {
    test('success path – returns parsed MatchInsight on 200', () async {
      final client = MockClient((request) async {
        return http.Response(json.encode(insightJson()), 200);
      });

      final service = MatchInsightService(
        client: client,
        tokenProvider: () async => 'test-token',
      );

      final insight = await service.fetchInsight(42);

      expect(insight, isNotNull);
      expect(insight, isA<MatchInsight>());
      expect(insight!.matchId, equals(42));
      expect(insight.overallScore, closeTo(0.87, 1e-9));
      expect(insight.reasons, containsAll(['shared interests', 'similar values']));
      expect(insight.friction, contains('different schedules'));
      expect(insight.growth, isNotNull);
      expect(insight.growth, contains('travel together'));
    });

    test('404 returns null – insight not yet generated', () async {
      final client = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final service = MatchInsightService(
        client: client,
        tokenProvider: () async => 'test-token',
      );

      final insight = await service.fetchInsight(99);
      expect(insight, isNull);
    });

    test('non-2xx non-404 throws ApiException', () async {
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = MatchInsightService(
        client: client,
        tokenProvider: () async => 'test-token',
      );

      await expectLater(
        () => service.fetchInsight(1),
        throwsA(isA<ApiException>()),
      );
    });

    test('cache hit avoids a second HTTP request', () async {
      int callCount = 0;

      final client = MockClient((request) async {
        callCount++;
        return http.Response(json.encode(insightJson()), 200);
      });

      final service = MatchInsightService(
        client: client,
        tokenProvider: () async => 'test-token',
      );

      final first = await service.fetchInsight(42);
      final second = await service.fetchInsight(42);

      // Only one HTTP call should have been made.
      expect(callCount, equals(1));
      expect(first!.matchId, equals(second!.matchId));
      expect(first.overallScore, equals(second.overallScore));
    });

    test('TTL expiry triggers a refetch', () async {
      int callCount = 0;

      final client = MockClient((request) async {
        callCount++;
        return http.Response(json.encode(insightJson()), 200);
      });

      // Very short TTL so the cache entry expires quickly in the test.
      final service = MatchInsightService(
        client: client,
        tokenProvider: () async => 'test-token',
        cacheTtl: const Duration(milliseconds: 50),
      );

      await service.fetchInsight(42);
      // Wait for the cache entry to expire.
      await Future.delayed(const Duration(milliseconds: 100));
      await service.fetchInsight(42);

      expect(callCount, equals(2));
    });

    test('null token returns null without making an HTTP request', () async {
      int callCount = 0;

      final client = MockClient((request) async {
        callCount++;
        return http.Response(json.encode(insightJson()), 200);
      });

      final service = MatchInsightService(
        client: client,
        tokenProvider: () async => null,
      );

      final insight = await service.fetchInsight(42);
      expect(insight, isNull);
      expect(callCount, equals(0));
    });

    test('request includes correct Authorization header and URL', () async {
      String? capturedAuth;
      Uri? capturedUri;

      final client = MockClient((request) async {
        capturedAuth = request.headers['Authorization'];
        capturedUri = request.url;
        return http.Response(json.encode(insightJson(matchId: 7)), 200);
      });

      final service = MatchInsightService(
        client: client,
        tokenProvider: () async => 'bearer-xyz',
      );

      await service.fetchInsight(7);

      expect(capturedAuth, equals('Bearer bearer-xyz'));
      expect(capturedUri?.path, contains('/api/matchmaking/matches/7/insight'));
    });

    test('MatchInsight.fromJson / toJson round-trip', () {
      final original = MatchInsight(
        matchId: 10,
        overallScore: 0.75,
        reasons: ['reason1'],
        friction: ['friction1'],
        growth: ['growth1'],
      );

      final json = original.toJson();
      final restored = MatchInsight.fromJson(json);

      expect(restored.matchId, equals(original.matchId));
      expect(restored.overallScore, equals(original.overallScore));
      expect(restored.reasons, equals(original.reasons));
      expect(restored.friction, equals(original.friction));
      expect(restored.growth, equals(original.growth));
    });

    test('MatchInsight.fromJson with null growth', () {
      final json = {
        'matchId': 5,
        'overallScore': 0.5,
        'reasons': <String>[],
        'friction': <String>[],
        'growth': null,
      };

      final insight = MatchInsight.fromJson(json);
      expect(insight.growth, isNull);
    });
  });
}
