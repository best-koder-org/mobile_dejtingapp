import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:dejtingapp/screens/forum_feed_screen.dart';
import 'package:dejtingapp/services/forum_service.dart';

import '../helpers/core_screen_test_helper.dart';

/// No token is vended in widget tests, so the feed settles into its error state. Every
/// assertion below is therefore about the screen chrome and the composer rather than
/// about loaded content — those are covered by test/services/forum_service_test.dart.
void main() {
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        if (call.method == 'read') return null;
        if (call.method == 'readAll') return <String, String>{};
        if (call.method == 'write') return null;
        return null;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (call) async {
        if (call.method == 'getAll') return <String, dynamic>{};
        return null;
      },
    );
  });

  Future<void> pumpFeed(WidgetTester tester) async {
    await tester.pumpWidget(
      buildCoreScreenTestApp(home: const ForumFeedScreen()),
    );
    // Let initState's async load settle into its error state.
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('ForumFeedScreen', () {
    testWidgets('shows the Community title', (tester) async {
      await pumpFeed(tester);

      expect(find.text('Community'), findsOneWidget);
    });

    testWidgets('offers an All chip alongside the channel chips', (tester) async {
      await pumpFeed(tester);

      expect(find.text('All'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsWidgets);
      // First channel after "All", so it is on screen without scrolling.
      expect(find.text('App feedback'), findsOneWidget);
    });

    testWidgets('shows a compose action', (tester) async {
      await pumpFeed(tester);

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('New Post'), findsOneWidget);
    });

    testWidgets('composer takes a single capped field and no title', (tester) async {
      await pumpFeed(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Post'), findsOneWidget);
      expect(find.text('Channel'), findsOneWidget);

      // A topic is one short text plus a channel — there is deliberately no title input.
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.maxLength, 200);
      expect(field.maxLines, 4);
    });

    testWidgets('submitting an empty topic is refused with a message', (tester) async {
      await pumpFeed(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Post'));
      await tester.pump();

      expect(find.text('Write something first.'), findsOneWidget);
    });

    testWidgets('the composer stays open after a refusal so the text is not lost',
        (tester) async {
      await pumpFeed(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'En fråga');
      await tester.tap(find.text('Post'));
      await tester.pump();

      // A failed submit must not dismiss the sheet.
      expect(find.text('Post'), findsOneWidget);
      expect(find.text('En fråga'), findsOneWidget);
    });

    testWidgets('renders without crashing when the feed cannot load', (tester) async {
      await pumpFeed(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ForumFeedScreen), findsOneWidget);
    });
  });

  group('ForumFeedScreen — forum service unreachable', () {
    // The gateway answers 502 when it cannot reach forum-service, which is exactly what
    // happens when the stack is not running. The screen used to collapse that into a plain
    // "could not load the forum", which reads like an empty feed or a bad request and hides
    // the one thing the user needs to know: the service behind the gateway is not up.
    const unreachable =
        "Can't reach the forum right now. It may still be starting up.";

    Future<void> pumpWithStatus(WidgetTester tester, int status) async {
      final client = MockClient(
          (_) async => http.Response(json.encode({'error': 'Bad Gateway'}), status));
      final service = ForumService.testing(client: client);

      await tester.pumpWidget(
        buildCoreScreenTestApp(home: ForumFeedScreen(service: service)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    for (final status in <int>[502, 503, 504]) {
      testWidgets('a $status explains the backend is unreachable', (tester) async {
        await pumpWithStatus(tester, status);

        expect(find.text(unreachable), findsOneWidget);
        expect(find.text('Could not load the forum.'), findsNothing);
      });
    }

    testWidgets('a real error still reads as a plain load failure', (tester) async {
      await pumpWithStatus(tester, 400);

      expect(find.text('Could not load the forum.'), findsOneWidget);
      expect(find.text(unreachable), findsNothing);
    });
  });
}
