
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/services/billing_service.dart';

void main() {
  group('EntitlementStatus.fromJson', () {
    test('parses tier as int 0 (Free)', () {
      final json = {
        'userId': 'user-123',
        'tier': 0,
        'expiresAt': null,
        'isPremium': false,
        'sparksBalance': 0,
        'sparksDailyUsed': 0,
        'sparksDailyMax': 0,
        'sparksDailyRemaining': 0,
      };
      final status = EntitlementStatus.fromJson(json);
      expect(status.tier, equals('Free'));
      expect(status.isPremium, isFalse);
      expect(status.userId, equals('user-123'));
    });

    test('parses tier as int 1 (Premium)', () {
      final json = {
        'userId': 'user-456',
        'tier': 1,
        'expiresAt': '2026-12-31T23:59:59Z',
        'isPremium': true,
        'sparksBalance': 500,
        'sparksDailyUsed': 1,
        'sparksDailyMax': 2,
        'sparksDailyRemaining': 1,
      };
      final status = EntitlementStatus.fromJson(json);
      expect(status.tier, equals('Premium'));
      expect(status.isPremium, isTrue);
      expect(status.sparksBalance, equals(500));
      expect(status.sparksDailyRemaining, equals(1));
      expect(status.availableSparks, equals(1));
    });

    test('parses tier as string "Premium"', () {
      final json = {
        'userId': 'user-789',
        'tier': 'Premium',
        'expiresAt': null,
        'isPremium': true,
        'sparksBalance': 1000,
        'sparksDailyUsed': 2,
        'sparksDailyMax': 2,
        'sparksDailyRemaining': 0,
      };
      final status = EntitlementStatus.fromJson(json);
      expect(status.tier, equals('Premium'));
      expect(status.isPremium, isTrue);
      expect(status.availableSparks, equals(1000));
    });

    test('handles missing tier gracefully', () {
      final json = {
        'userId': 'user-000',
        'isPremium': false,
        'sparksBalance': 0,
        'sparksDailyUsed': 0,
        'sparksDailyMax': 0,
        'sparksDailyRemaining': 0,
      };
      final status = EntitlementStatus.fromJson(json);
      expect(status.tier, equals('Free'));
    });

    test('availableSparks uses dailyRemaining when > 0', () {
      final json = {
        'userId': 'user-premium',
        'tier': 1,
        'expiresAt': null,
        'isPremium': true,
        'sparksBalance': 100,
        'sparksDailyUsed': 1,
        'sparksDailyMax': 2,
        'sparksDailyRemaining': 1,
      };
      final status = EntitlementStatus.fromJson(json);
      expect(status.availableSparks, equals(1));
    });

    test('availableSparks falls back to balance when dailyRemaining is 0', () {
      final json = {
        'userId': 'user-no-daily',
        'tier': 0,
        'expiresAt': null,
        'isPremium': false,
        'sparksBalance': 200,
        'sparksDailyUsed': 0,
        'sparksDailyMax': 0,
        'sparksDailyRemaining': 0,
      };
      final status = EntitlementStatus.fromJson(json);
      expect(status.availableSparks, equals(200));
    });
  });

  group('SparkReceived.fromJson', () {
    test('parses complete spark record', () {
      final json = {
        'id': 42,
        'senderUserId': 'sender-1',
        'recipientUserId': 'recipient-1',
        'message': 'Hey there!',
        'isRead': false,
        'createdAt': '2026-06-14T12:00:00',
        'senderDisplayName': 'Alice',
        'senderPhotoUrl': 'http://example.com/photo.jpg',
      };
      final spark = SparkReceived.fromJson(json);
      expect(spark.id, equals(42));
      expect(spark.senderUserId, equals('sender-1'));
      expect(spark.message, equals('Hey there!'));
      expect(spark.isRead, isFalse);
      expect(spark.senderDisplayName, equals('Alice'));
    });

    test('parses spark without message', () {
      final json = {
        'id': 7,
        'senderUserId': 'sender-2',
        'recipientUserId': 'recipient-2',
        'message': null,
        'isRead': true,
        'createdAt': '2026-06-14T10:00:00',
      };
      final spark = SparkReceived.fromJson(json);
      expect(spark.id, equals(7));
      expect(spark.message, isNull);
      expect(spark.isRead, isTrue);
    });
  });

  group('Realistic API response parsing (no crash)', () {
    test('parses real GET /api/billing/status response with int tier', () {
      final raw = '{\n'
          '  "userId": "167d5636-f945-4726-9fd8-fd1d8d9b96c9",\n'
          '  "tier": 1,\n'
          '  "expiresAt": "2027-03-11T08:50:00.027238",\n'
          '  "isPremium": true,\n'
          '  "sparksBalance": 1498,\n'
          '  "sparksDailyUsed": 2,\n'
          '  "sparksDailyMax": 2,\n'
          '  "sparksDailyRemaining": 0\n'
          '}';
      final json = jsonDecode(raw) as Map<String, dynamic>;
      expect(() => EntitlementStatus.fromJson(json), returnsNormally);
      final status = EntitlementStatus.fromJson(json);
      expect(status.tier, equals('Premium'));
      expect(status.availableSparks, equals(1498));
    });

    test('parses real POST /api/billing/purchase response for premium_month', () {
      final raw = '{\n'
          '  "success": true,\n'
          '  "data": {\n'
          '    "userId": "167d5636-f945-4726-9fd8-fd1d8d9b96c9",\n'
          '    "tier": 1,\n'
          '    "expiresAt": "2027-03-11T08:50:00.027238"\n'
          '  },\n'
          '  "message": "Sandbox purchase complete"\n'
          '}';
      final body = jsonDecode(raw) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      final tierValue = data['tier'];
      expect(() {
        final tierStr = tierValue is int
            ? (tierValue == 1 ? 'Premium' : 'Free')
            : tierValue?.toString() ?? 'Free';
        expect(tierStr, equals('Premium'));
      }, returnsNormally);
    });

    test('parses real POST /api/billing/purchase response for sparks_100', () {
      final raw = '{\n'
          '  "success": true,\n'
          '  "data": {\n'
          '    "userId": "167d5636-f945-4726-9fd8-fd1d8d9b96c9",\n'
          '    "newBalance": 100\n'
          '  },\n'
          '  "message": "Sandbox purchase complete"\n'
          '}';
      final body = jsonDecode(raw) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      final balance = data['newBalance'] as int?;
      expect(balance, equals(100));
    });

    test('parses real GET /api/billing/sparks/received response', () {
      final raw = '{\n'
          '  "success": true,\n'
          '  "data": {\n'
          '    "sparks": [\n'
          '      {\n'
          '        "id": 1,\n'
          '        "senderUserId": "167d5636-f945-4726-9fd8-fd1d8d9b96c9",\n'
          '        "recipientUserId": "3f69f757-e81c-4516-bf36-1213f6edc1cf",\n'
          '        "message": "Hey Alice!",\n'
          '        "isRead": false,\n'
          '        "createdAt": "2026-06-14T08:33:22.916611",\n'
          '        "senderDisplayName": null,\n'
          '        "senderPhotoUrl": null\n'
          '      }\n'
          '    ],\n'
          '    "totalCount": 1\n'
          '  }\n'
          '}';
      final body = jsonDecode(raw) as Map<String, dynamic>;
      final resultData = body['data'] as Map<String, dynamic>;
      final sparks = (resultData['sparks'] as List)
          .map((s) => SparkReceived.fromJson(s as Map<String, dynamic>))
          .toList();
      expect(sparks.length, equals(1));
      expect(sparks[0].id, equals(1));
      expect(sparks[0].message, equals('Hey Alice!'));
    });
  });
}
