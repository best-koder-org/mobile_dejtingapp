import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dejtingapp/screens/post_date_feedback_screen.dart';
import '../helpers/core_screen_test_helper.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

Widget buildScreen({
  String matchId = 'match-123',
  String? matchedPersonName = 'Maja',
  http.Client? httpClient,
}) {
  return buildCoreScreenTestApp(
    home: PostDateFeedbackScreen(
      matchId: matchId,
      matchedPersonName: matchedPersonName,
      httpClient: httpClient,
      tokenProvider: () async => null, // skip FlutterSecureStorage in tests
    ),
  );
}

// Stars a rating row by tapping the Nth star.
Future<void> tapStar(WidgetTester tester, String label, int star) async {
  final row = find.ancestor(
    of: find.text(label),
    matching: find.byType(Row),
  );
  final stars = find.descendant(of: row, matching: find.byType(GestureDetector));
  await tester.tap(stars.at(star - 1));
  await tester.pump();
}

Future<void> tapSubmit(WidgetTester tester) async {
  final btn = find.byKey(const Key('submit_feedback_btn'));
  await tester.ensureVisible(btn);
  await tester.pump();
  await tester.tap(btn);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => setupTestHttpOverrides());

  group('PostDateFeedbackScreen', () {
    testWidgets('renders rating rows and submit button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Helhetsbetyg'), findsOneWidget);
      expect(find.text('Kemi'), findsOneWidget);
      expect(find.text('Samtal'), findsOneWidget);
      expect(find.byKey(const Key('submit_feedback_btn')), findsOneWidget);
    });

    testWidgets('submit button is disabled before all ratings selected', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(
          find.byKey(const Key('submit_feedback_btn')));
      expect(btn.onPressed, isNull);
    });

    testWidgets('submit button enables after all three ratings selected', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tapStar(tester, 'Helhetsbetyg', 4);
      await tapStar(tester, 'Kemi', 3);
      await tapStar(tester, 'Samtal', 5);

      final btn = tester.widget<ElevatedButton>(
          find.byKey(const Key('submit_feedback_btn')));
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('shows match person name in heading', (tester) async {
      await tester.pumpWidget(buildScreen(matchedPersonName: 'Erik'));
      await tester.pump();

      expect(find.textContaining('Erik'), findsWidgets);
    });

    testWidgets('toggles WouldMeetAgain switch', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<Switch>(switchFinder).value, isFalse);

      await tester.tap(switchFinder);
      await tester.pump();

      expect(tester.widget<Switch>(switchFinder).value, isTrue);
    });

    testWidgets('successful submit pops screen', (tester) async {
      var submitted = false;

      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path,
            contains('/api/matchmaking/matches/match-123/feedback'));
        submitted = true;
        return http.Response(jsonEncode({'feedbackId': 42}), 200,
            headers: {'content-type': 'application/json'});
      });

      await tester.pumpWidget(buildScreen(httpClient: mockClient));
      await tester.pump();

      await tapStar(tester, 'Helhetsbetyg', 4);
      await tapStar(tester, 'Kemi', 3);
      await tapStar(tester, 'Samtal', 5);

      await tapSubmit(tester);

      expect(submitted, isTrue);
    });

    testWidgets('duplicate response shows conflict error', (tester) async {
      final mockClient = MockClient((_) async =>
          http.Response(jsonEncode({'error': 'Duplicate'}), 409,
              headers: {'content-type': 'application/json'}));

      await tester.pumpWidget(buildScreen(httpClient: mockClient));
      await tester.pump();

      await tapStar(tester, 'Helhetsbetyg', 2);
      await tapStar(tester, 'Kemi', 2);
      await tapStar(tester, 'Samtal', 2);

      await tapSubmit(tester);

      expect(find.textContaining('redan'), findsOneWidget);
    });

    testWidgets('network error shows error message', (tester) async {
      final mockClient = MockClient((_) async => throw const SocketException('no net'));

      await tester.pumpWidget(buildScreen(httpClient: mockClient));
      await tester.pump();

      await tapStar(tester, 'Helhetsbetyg', 1);
      await tapStar(tester, 'Kemi', 1);
      await tapStar(tester, 'Samtal', 1);

      await tapSubmit(tester);

      expect(find.textContaining('Nätverksfel'), findsOneWidget);
    });
  });
}
