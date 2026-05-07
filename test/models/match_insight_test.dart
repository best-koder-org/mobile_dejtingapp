// Tests for lib/models/match_insight.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:dejtingapp/models/match_insight.dart';

void main() {
  group('MatchInsight', () {
    test('fromJson / toJson round-trip preserves all fields', () {
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

    test('fromJson with null growth sets growth to null', () {
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

    test('toJson omits growth key when growth is null', () {
      final insight = MatchInsight(
        matchId: 1,
        overallScore: 0.5,
        reasons: [],
        friction: [],
      );

      final json = insight.toJson();
      expect(json.containsKey('growth'), isFalse);
    });

    test('fromJson parses overallScore from int JSON value', () {
      final json = {
        'matchId': 3,
        'overallScore': 1,
        'reasons': <String>[],
        'friction': <String>[],
      };

      final insight = MatchInsight.fromJson(json);
      expect(insight.overallScore, equals(1.0));
      expect(insight.overallScore, isA<double>());
    });
  });
}
