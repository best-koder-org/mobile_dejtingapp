import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:dejtingapp/screens/forum_topic_screen.dart';
import 'package:dejtingapp/services/forum_service.dart';

import '../helpers/core_screen_test_helper.dart';

/// The topic sub-page: the topic pinned on top, its answers listed underneath, and every
/// answer votable on its own.
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

  ForumTopic topic({int id = 3, int voteScore = 5, int myVote = 0}) => ForumTopic(
        id: id,
        text: 'Ar det ok att gilla tva personer?',
        channel: 'ask',
        createdAt: DateTime.utc(2026, 9, 13, 8),
        expiresAt: DateTime.utc(2026, 9, 15, 8),
        voteScore: voteScore,
        answerCount: 1,
        isOwn: false,
        myVote: myVote,
        colorHex: '#FF7F50',
        pseudonym: 'Anonym ravv',
      );

  Map<String, dynamic> answerJson({
    int id = 7,
    int voteScore = 2,
    int myVote = 0,
    bool isOwn = false,
  }) =>
      {
        'id': id,
        'topicId': 3,
        'text': 'Ja absolut, det ar val bara bra.',
        'createdAt': '2026-09-13T08:00:00Z',
        'voteScore': voteScore,
        'myVote': myVote,
        'isOwn': isOwn,
        'colorHex': '#4CAF50',
        'pseudonym': 'Anonym gras',
      };

  MockClient answersClient(List<Map<String, dynamic>> items, {void Function(http.Request)? onPost}) =>
      MockClient((request) async {
        if (request.method == 'POST') {
          onPost?.call(request);
          return http.Response(json.encode({'voteScore': 3, 'myVote': 1}), 200);
        }
        return http.Response(
          json.encode({'total': items.length, 'page': 1, 'pageSize': 20, 'items': items}),
          200,
        );
      });

  Future<void> pumpTopic(WidgetTester tester, ForumService service) async {
    await tester.pumpWidget(
      buildCoreScreenTestApp(home: ForumTopicScreen(topic: topic(), service: service)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('ForumTopicScreen', () {
    testWidgets('keeps the topic on top of its answers', (tester) async {
      await pumpTopic(tester, ForumService.testing(client: answersClient([answerJson()])));

      expect(find.text('Ar det ok att gilla tva personer?'), findsOneWidget);
      expect(find.text('Ja absolut, det ar val bara bra.'), findsOneWidget);
      // The topic's own score, from the card that was tapped.
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('lists every answer, one under the other', (tester) async {
      await pumpTopic(
        tester,
        ForumService.testing(
          client: answersClient([
            answerJson(id: 1, voteScore: 1),
            answerJson(id: 2, voteScore: 2),
            answerJson(id: 3, voteScore: 3),
          ]),
        ),
      );

      expect(find.text('Ja absolut, det ar val bara bra.'), findsNWidgets(3));
    });

    testWidgets('an answer without votes shows a neutral zero', (tester) async {
      await pumpTopic(tester, ForumService.testing(client: answersClient([answerJson(voteScore: 0)])));

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('voting on an answer posts to the answers endpoint', (tester) async {
      http.Request? posted;
      await pumpTopic(
        tester,
        ForumService.testing(
          client: answersClient([answerJson(id: 77)], onPost: (r) => posted = r),
        ),
      );

      // Answers sit below the topic header, so the up arrow there is the topic's.
      // The answer's arrows are the later ones in the tree.
      final upArrows = find.byIcon(Icons.keyboard_arrow_up);
      expect(upArrows, findsNWidgets(2));
      await tester.tap(upArrows.last);
      await tester.pump(const Duration(milliseconds: 100));

      expect(posted, isNotNull);
      expect(posted!.url.path, '/api/forum/answers/77/vote');
    });

    testWidgets('a 502 says the backend is unreachable, not just "could not load"',
        (tester) async {
      final client = MockClient(
          (_) async => http.Response(json.encode({'error': 'Bad Gateway'}), 502));

      await pumpTopic(tester, ForumService.testing(client: client));

      expect(
        find.text("Can't reach the forum right now. It may still be starting up."),
        findsOneWidget,
      );
      expect(find.text('Could not load the forum.'), findsNothing);
    });

    testWidgets('an empty thread invites the first reply', (tester) async {
      await pumpTopic(tester, ForumService.testing(client: answersClient([])));

      expect(find.text('No answers yet. Be the first to reply.'), findsOneWidget);
    });
  });
}
