import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:dejtingapp/services/forum_service.dart';

/// The forum contract is easy to drift, so these tests pin the exact wire shape the
/// Flutter client expects: paths, verbs, status codes and field names.
void main() {
  ForumService serviceWith(MockClient client, {Future<String?> Function()? token}) =>
      ForumService.testing(client: client, token: token);

  group('channels', () {
    test('are the frozen slugs shared with the server', () {
      expect(ForumService.channels, <String>[
        'feedback',
        'first-dates',
        'red-flags',
        'vent',
        'success-stories',
        'ask',
      ]);
    });

    test('limit mirrors the server text cap', () {
      expect(ForumService.maxTextLength, 200);
    });
  });

  group('listTopics', () {
    test('parses a paged response and keeps the anonymous identity', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/forum/topics');
        expect(request.headers['Authorization'], 'Bearer test-token');
        return http.Response(
          json.encode({
            'total': 1,
            'page': 1,
            'pageSize': 20,
            'items': [
              {
                'id': 7,
                'text': 'Första dejten?',
                'channel': 'first-dates',
                'createdAt': '2026-09-12T10:00:00Z',
                'expiresAt': '2026-09-14T10:00:00Z',
                'voteScore': 3,
                'answerCount': 2,
                'isOwn': false,
                'myVote': 1,
                'colorHex': '#4FC3F7',
                'pseudonym': 'Gröna Duvan',
              }
            ],
          }),
          200,
        );
      });

      final result = await serviceWith(client).listTopics();

      expect(result.ok, isTrue);
      expect(result.data!.total, 1);
      expect(result.data!.hasMore, isFalse);

      final topic = result.data!.items.single;
      expect(topic.id, 7);
      expect(topic.text, 'Första dejten?');
      expect(topic.channel, 'first-dates');
      expect(topic.voteScore, 3);
      expect(topic.answerCount, 2);
      expect(topic.myVote, 1);
      expect(topic.pseudonym, 'Gröna Duvan');
      expect(topic.colorHex, '#4FC3F7');
      expect(topic.isOwn, isFalse);
    });

    test('hasMore reflects an unfetched second page', () async {
      final client = MockClient((_) async => http.Response(
            json.encode({'total': 25, 'page': 1, 'pageSize': 20, 'items': []}),
            200,
          ));

      final page = (await serviceWith(client).listTopics()).data!;

      expect(page.hasMore, isTrue);
    });

    test('sends the channel, sort and paging parameters', () async {
      late Uri seen;
      final client = MockClient((request) async {
        seen = request.url;
        return http.Response(
          json.encode({'total': 0, 'page': 2, 'pageSize': 5, 'items': []}),
          200,
        );
      });

      await serviceWith(client)
          .listTopics(channel: 'vent', sort: 'top', page: 2, pageSize: 5);

      expect(seen.queryParameters['channel'], 'vent');
      expect(seen.queryParameters['sort'], 'top');
      expect(seen.queryParameters['page'], '2');
      expect(seen.queryParameters['pageSize'], '5');
    });

    test('omits the channel parameter when every channel is requested', () async {
      late Uri seen;
      final client = MockClient((request) async {
        seen = request.url;
        return http.Response(
          json.encode({'total': 0, 'page': 1, 'pageSize': 20, 'items': []}),
          200,
        );
      });

      await serviceWith(client).listTopics();

      expect(seen.queryParameters.containsKey('channel'), isFalse);
    });

    test('surfaces the backend error message', () async {
      final client = MockClient(
          (_) async => http.Response(json.encode({'error': 'Unknown channel'}), 400));

      final result = await serviceWith(client).listTopics(channel: 'nope');

      expect(result.ok, isFalse);
      expect(result.statusCode, 400);
      expect(result.error, 'Unknown channel');
    });
  });

  group('createTopic', () {
    test('posts the trimmed text and channel, then reads the id from a 201', () async {
      Map<String, dynamic>? sent;
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/forum/topics');
        sent = json.decode(request.body) as Map<String, dynamic>;
        return http.Response(json.encode({'id': 42}), 201);
      });

      final result =
          await serviceWith(client).createTopic(text: '  hej  ', channel: 'vent');

      expect(result.ok, isTrue);
      expect(result.data, 42);
      expect(sent!['text'], 'hej');
      expect(sent!['channel'], 'vent');
      expect(sent!.containsKey('isAnonymous'), isFalse,
          reason: 'anonymity is implicit now; the flag was removed from the contract');
    });

    test('flags a 429 as rate limited', () async {
      final client = MockClient((_) async => http.Response(
          json.encode({'error': 'You are posting too quickly. Try again in 30s.'}), 429));

      final result = await serviceWith(client).createTopic(text: 'hej', channel: 'vent');

      expect(result.ok, isFalse);
      expect(result.isRateLimited, isTrue);
    });

    test('flags a 422 as held for review and decodes a non-ASCII reason', () async {
      // The real backend sends an em-dash here. http.Response defaults to latin-1, so the
      // charset has to be explicit or this throws instead of exercising the decode path.
      final client = MockClient((_) async => http.Response(
            json.encode({'error': 'Contains contact details — remove them to post.'}),
            422,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          ));

      final result = await serviceWith(client).createTopic(text: 'a@b.se', channel: 'vent');

      expect(result.isHeldForReview, isTrue);
      expect(result.error, contains('contact details —'));
    });

    test('treats a 200 as a failure because the API contract says 201', () async {
      final client = MockClient((_) async => http.Response(json.encode({'id': 1}), 200));

      final result = await serviceWith(client).createTopic(text: 'hej', channel: 'vent');

      expect(result.ok, isFalse);
    });
  });

  group('voteTopic', () {
    test('sends the value and returns the new score', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/forum/topics/7/vote');
        expect(json.decode(request.body)['value'], -1);
        return http.Response(json.encode({'voteScore': -1, 'myVote': -1}), 200);
      });

      final result = await serviceWith(client).voteTopic(7, -1);

      expect(result.ok, isTrue);
      expect(result.data, -1);
    });

    test('surfaces the self-vote rejection', () async {
      final client = MockClient((_) async => http.Response(
          json.encode({'error': 'You cannot vote on your own topic.'}), 422));

      final result = await serviceWith(client).voteTopic(7, 1);

      expect(result.ok, isFalse);
      expect(result.error, 'You cannot vote on your own topic.');
    });
  });

  group('answers', () {
    test('createAnswer posts under the topic and expects a 201', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/forum/topics/7/answers');
        expect(json.decode(request.body)['text'], 'Håller med!');
        return http.Response(json.encode({'id': 99}), 201);
      });

      final result = await serviceWith(client).createAnswer(7, 'Håller med!');

      expect(result.ok, isTrue);
      expect(result.data, 99);
    });

    test('createAnswer treats a 200 as a failure', () async {
      final client = MockClient((_) async => http.Response(json.encode({'id': 99}), 200));

      expect((await serviceWith(client).createAnswer(7, 'x')).ok, isFalse);
    });

    test('listAnswers parses the paged shape', () async {
      final client = MockClient((_) async => http.Response(
            json.encode({
              'total': 1,
              'page': 1,
              'pageSize': 20,
              'items': [
                {
                  'id': 5,
                  'topicId': 7,
                  'text': 'Samma här',
                  'createdAt': '2026-09-12T11:00:00Z',
                  'isOwn': true,
                  'colorHex': '#81C784',
                  'pseudonym': 'Blå Räven',
                }
              ],
            }),
            200,
          ));

      final answer =
          (await serviceWith(client).listAnswers(7)).data!.items.single;

      expect(answer.id, 5);
      expect(answer.topicId, 7);
      expect(answer.text, 'Samma här');
      expect(answer.isOwn, isTrue);
      expect(answer.pseudonym, 'Blå Räven');
    });
  });

  group('deletes', () {
    test('deleteTopic treats 204 as success', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/forum/topics/7');
        return http.Response('', 204);
      });

      expect((await serviceWith(client).deleteTopic(7)).ok, isTrue);
    });

    test('deleteAnswer treats 403 as a failure', () async {
      final client = MockClient((_) async => http.Response('', 403));

      final result = await serviceWith(client).deleteAnswer(5);

      expect(result.ok, isFalse);
      expect(result.statusCode, 403);
    });
  });

  group('auth', () {
    test('reports signed-out without touching the network', () async {
      var called = false;
      final client = MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      });

      final result = await ForumService.testing(client: client, token: () async => null)
          .listTopics();

      expect(result.ok, isFalse);
      expect(result.statusCode, 401);
      expect(called, isFalse);
    });
  });

  group('reporting', () {
    test('reportTopic posts the topicId and expects a 201', () async {
      Map<String, dynamic>? sent;
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/forum/report');
        sent = json.decode(request.body) as Map<String, dynamic>;
        return http.Response(json.encode({'id': 555}), 201);
      });

      final result = await serviceWith(client).reportTopic(7, reason: 'Obehagligt');

      expect(result.ok, isTrue);
      expect(result.data, 555);
      expect(sent!['topicId'], 7);
      expect(sent!['reason'], 'Obehagligt');
    });

    test('reportAnswer sends answerId rather than topicId', () async {
      Map<String, dynamic>? sent;
      final client = MockClient((request) async {
        sent = json.decode(request.body) as Map<String, dynamic>;
        return http.Response(json.encode({'id': 556}), 201);
      });

      await serviceWith(client).reportAnswer(12);

      expect(sent!['answerId'], 12);
      expect(sent!.containsKey('topicId'), isFalse);
    });

    test('surfaces the self-report rejection', () async {
      final client = MockClient((_) async => http.Response(
          json.encode({'error': 'You cannot report your own post.'}), 422));

      final result = await serviceWith(client).reportTopic(7);

      expect(result.ok, isFalse);
      expect(result.error, 'You cannot report your own post.');
    });

    test('a 503 means reporting is unavailable, not silently fine', () async {
      final client = MockClient((_) async => http.Response(
          json.encode({'error': 'Reporting is unavailable right now.'}), 503));

      final result = await serviceWith(client).reportTopic(7);

      expect(result.ok, isFalse);
      expect(result.isUnavailable, isTrue);
    });
  });

  group('backend unavailable', () {
    // A 502 is what the gateway returns when it cannot reach forum-service, and that is the
    // most common local failure: the stack simply is not running. Only 503 used to count as
    // "unavailable", so a dead backend surfaced as a generic failure and the app said
    // "could not load the forum" — implying an empty feed or a bad request rather than a
    // service that is down.
    for (final code in <int>[502, 503, 504]) {
      test('a $code is reported as the backend being unavailable', () async {
        final client = MockClient(
            (_) async => http.Response(json.encode({'error': 'Bad Gateway'}), code));

        final result = await serviceWith(client).listTopics();

        expect(result.ok, isFalse);
        expect(result.isUnavailable, isTrue,
            reason: '$code means the gateway answered but the service did not');
      });
    }

    test('creating a topic against a dead backend is unavailable, not a bad request',
        () async {
      final client = MockClient(
          (_) async => http.Response(json.encode({'error': 'Bad Gateway'}), 502));

      final result =
          await serviceWith(client).createTopic(text: 'hej', channel: 'vent');

      expect(result.ok, isFalse);
      expect(result.isUnavailable, isTrue);
      expect(result.isRateLimited, isFalse);
      expect(result.isHeldForReview, isFalse);
    });

    test('real answers are not mistaken for an outage', () async {
      // These all mean the forum responded and had something to say, so the UI must not
      // tell the user the service is down.
      for (final code in <int>[400, 401, 403, 404, 422, 429, 500]) {
        final client = MockClient(
            (_) async => http.Response(json.encode({'error': 'nope'}), code));

        final result = await serviceWith(client).listTopics();

        expect(result.isUnavailable, isFalse, reason: '$code is a real response');
      }
    });
  });
}
