import 'dart:convert';

import 'package:dejtingapp/screens/match_insight_screen.dart';
import 'package:dejtingapp/services/match_insight_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Test fakes ----------------------------------------------------------------

MatchInsightService _serviceReturning({
  required Map<String, dynamic> body,
  int statusCode = 200,
}) {
  final mock = MockClient((req) async {
    return http.Response(
      jsonEncode(body),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  });
  return MatchInsightService(
    client: mock,
    tokenProvider: () async => 'fake-token',
  );
}

MatchInsightService _serviceReturningStatus(int status) {
  final mock = MockClient((req) async => http.Response('', status));
  return MatchInsightService(
    client: mock,
    tokenProvider: () async => 'fake-token',
  );
}

MatchInsightService _serviceThrowing() {
  final mock = MockClient((req) async => throw Exception('network down'));
  return MatchInsightService(
    client: mock,
    tokenProvider: () async => 'fake-token',
  );
}

const _fullPayload = {
  'matchId': 42,
  'overallScore': 0.87,
  'reasons': [
    'Both score high on openness',
    'Aligned on family values',
    'Compatible attachment styles',
  ],
  'friction': [
    'You prefer planning, they prefer spontaneity',
    'Different sleep schedules',
  ],
  'growth': [
    'Your stability could ground their spontaneity',
  ],
};

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  // Tall test surface so the whole ListView fits without scrolling.
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.views.first.physicalSize =
        const Size(800, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  group('MatchInsightScreen', () {
    testWidgets('renders the 3 content sections and the locked premium card',
        (tester) async {
      final service = _serviceReturning(body: _fullPayload);

      await tester.pumpWidget(_wrap(
        MatchInsightScreen(matchId: 42, insightService: service),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Why You Connected'), findsOneWidget);
      expect(find.text('Areas of Difference'), findsOneWidget);
      expect(find.text('Where This Could Go'), findsOneWidget);
      expect(find.text('What You Could Learn'), findsOneWidget);

      // First reason rendered.
      expect(find.text('Both score high on openness'), findsOneWidget);
      // Friction item rendered.
      expect(find.text('Different sleep schedules'), findsOneWidget);
      // Growth item rendered.
      expect(find.text('Your stability could ground their spontaneity'),
          findsOneWidget);

      // Percentage label rendered (0.87 → 87%).
      expect(find.text('87% compatible'), findsOneWidget);
    });

    testWidgets('caps friction list at 3 items', (tester) async {
      final service = _serviceReturning(body: {
        'matchId': 1,
        'overallScore': 0.5,
        'reasons': <String>[],
        'friction': ['a', 'b', 'c', 'd', 'e'],
      });

      await tester.pumpWidget(_wrap(
        MatchInsightScreen(matchId: 1, insightService: service),
      ));
      await tester.pumpAndSettle();

      expect(find.text('a'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
      expect(find.text('c'), findsOneWidget);
      expect(find.text('d'), findsNothing);
      expect(find.text('e'), findsNothing);
    });

    testWidgets('premium section is locked by default and unlocked when '
        'isPremium=true', (tester) async {
      final service = _serviceReturning(body: _fullPayload);

      await tester.pumpWidget(_wrap(
        MatchInsightScreen(matchId: 42, insightService: service),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      final premiumService = _serviceReturning(body: _fullPayload);
      await tester.pumpWidget(_wrap(
        MatchInsightScreen(
          matchId: 42,
          insightService: premiumService,
          isPremium: true,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lock_outline), findsNothing);
    });

    testWidgets('shows empty state when insight is 404', (tester) async {
      final service = _serviceReturningStatus(404);

      await tester.pumpWidget(_wrap(
        MatchInsightScreen(matchId: 99, insightService: service),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Insight not ready yet'), findsOneWidget);
      expect(find.text('Why You Connected'), findsNothing);
    });

    testWidgets('shows error state with retry button on network failure',
        (tester) async {
      final service = _serviceThrowing();

      await tester.pumpWidget(_wrap(
        MatchInsightScreen(matchId: 1, insightService: service),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not load insight'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    });

    testWidgets('title includes other user name when provided', (tester) async {
      final service = _serviceReturning(body: _fullPayload);

      await tester.pumpWidget(_wrap(
        MatchInsightScreen(
          matchId: 42,
          otherUserName: 'Maja',
          insightService: service,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Match with Maja'), findsOneWidget);
    });
  });
}
