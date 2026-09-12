import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../backend_url.dart';
import 'api_service.dart';

/// A topic as clients see it.
///
/// There is deliberately no author identifier: the backend exposes only a per-topic
/// anonymous [colorHex] and [pseudonym], which stay stable for one author within one
/// topic and differ across topics.
class ForumTopic {
  final int id;
  final String text;
  final String channel;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int voteScore;
  final int answerCount;
  final bool isOwn;
  final int myVote;
  final String colorHex;
  final String pseudonym;

  const ForumTopic({
    required this.id,
    required this.text,
    required this.channel,
    required this.createdAt,
    required this.expiresAt,
    required this.voteScore,
    required this.answerCount,
    required this.isOwn,
    required this.myVote,
    required this.colorHex,
    required this.pseudonym,
  });

  factory ForumTopic.fromJson(Map<String, dynamic> j) => ForumTopic(
        id: j['id'] as int,
        text: j['text'] as String? ?? '',
        channel: j['channel'] as String? ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
        expiresAt: DateTime.parse(j['expiresAt'] as String).toLocal(),
        voteScore: j['voteScore'] as int? ?? 0,
        answerCount: j['answerCount'] as int? ?? 0,
        isOwn: j['isOwn'] as bool? ?? false,
        myVote: j['myVote'] as int? ?? 0,
        colorHex: j['colorHex'] as String? ?? '#FF7F50',
        pseudonym: j['pseudonym'] as String? ?? '',
      );

  ForumTopic copyWith({int? voteScore, int? myVote, int? answerCount}) => ForumTopic(
        id: id,
        text: text,
        channel: channel,
        createdAt: createdAt,
        expiresAt: expiresAt,
        voteScore: voteScore ?? this.voteScore,
        answerCount: answerCount ?? this.answerCount,
        isOwn: isOwn,
        myVote: myVote ?? this.myVote,
        colorHex: colorHex,
        pseudonym: pseudonym,
      );

  /// Whole hours left before the topic drops out of the feed.
  int get hoursRemaining =>
      expiresAt.difference(DateTime.now()).inHours.clamp(0, 999);
}

/// A short anonymous reply under a topic.
class ForumAnswer {
  final int id;
  final int topicId;
  final String text;
  final DateTime createdAt;
  final bool isOwn;
  final String colorHex;
  final String pseudonym;

  const ForumAnswer({
    required this.id,
    required this.topicId,
    required this.text,
    required this.createdAt,
    required this.isOwn,
    required this.colorHex,
    required this.pseudonym,
  });

  factory ForumAnswer.fromJson(Map<String, dynamic> j) => ForumAnswer(
        id: j['id'] as int,
        topicId: j['topicId'] as int? ?? 0,
        text: j['text'] as String? ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
        isOwn: j['isOwn'] as bool? ?? false,
        colorHex: j['colorHex'] as String? ?? '#FF7F50',
        pseudonym: j['pseudonym'] as String? ?? '',
      );
}

/// One page of a forum list endpoint.
class ForumPage<T> {
  final int total;
  final int page;
  final int pageSize;
  final List<T> items;

  const ForumPage({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.items,
  });

  bool get hasMore => page * pageSize < total;
}

/// Result of a mutating call.
///
/// Carries the backend's own message so the UI can explain what happened:
/// 429 covers both the posting cooldown and the daily cap, 422 means the text was held
/// for review, and 503 means voice input is unavailable.
class ForumResult<T> {
  final bool ok;
  final T? data;
  final String? error;
  final int statusCode;

  const ForumResult._(this.ok, this.data, this.error, this.statusCode);

  factory ForumResult.success(T data, [int statusCode = 200]) =>
      ForumResult._(true, data, null, statusCode);

  factory ForumResult.failure(String error, int statusCode) =>
      ForumResult._(false, null, error, statusCode);

  bool get isRateLimited => statusCode == 429;
  bool get isHeldForReview => statusCode == 422;
  bool get isUnavailable => statusCode == 503;
}

/// Client for the anonymous forum.
///
/// Every call goes through the YARP gateway (see [ApiUrls.gateway]), which routes
/// `/api/forum/**` to forum-service.
class ForumService {
  static final ForumService _instance = ForumService._();
  factory ForumService() => _instance;

  ForumService._({http.Client? client, Future<String?> Function()? token})
      : _client = client ?? http.Client(),
        _tokenOverride = token;

  /// Test seam: a client and token source that touch neither the network nor Keycloak.
  @visibleForTesting
  static ForumService testing({
    required http.Client client,
    Future<String?> Function()? token,
  }) =>
      ForumService._(client: client, token: token ?? (() async => 'test-token'));

  final http.Client _client;
  final Future<String?> Function()? _tokenOverride;

  /// Mirrors ForumLimits.MaxTextLength on the server. Enforced here for the counter and
  /// the input formatter, and again by the API and the database.
  static const int maxTextLength = 200;

  /// Mirrors ForumLimits.MaxVoiceSeconds. A 200-character post is only ~20s of speech,
  /// and CPU transcription is slow, so recordings stay short.
  static const int maxVoiceSeconds = 20;

  /// Channel slugs, in display order. These are the wire format — see ForumChannels on
  /// the server. Renaming one is a breaking change on both sides.
  static const List<String> channels = <String>[
    'feedback',
    'first-dates',
    'red-flags',
    'vent',
    'success-stories',
    'ask',
  ];

  static String get _base => '${ApiUrls.gateway}/api/forum';

  Future<Map<String, String>?> _authHeader() async {
    final token = _tokenOverride != null
        ? await _tokenOverride()
        : await AppState().getOrRefreshAuthToken();
    if (token == null) return null;
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  }

  /// Pulls the backend's `{ "error": "..." }` message out of a failed response.
  String _messageFrom(http.Response response) {
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // Fall through to the generic message below.
    }
    return 'HTTP ${response.statusCode}';
  }

  /// Channel slugs the server accepts, in display order.
  Future<ForumResult<List<String>>> listChannels() async {
    try {
      final headers = await _authHeader();
      if (headers == null) return ForumResult.failure('Not signed in', 401);

      final response = await _client
          .get(Uri.parse('$_base/channels'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return ForumResult.failure(_messageFrom(response), response.statusCode);
      }
      final list = (json.decode(response.body) as List).cast<String>();
      return ForumResult.success(list);
    } catch (e) {
      debugPrint('ForumService.listChannels error: $e');
      return ForumResult.failure('Network error', 0);
    }
  }

  /// Paginated feed. [channel] null means every channel.
  Future<ForumResult<ForumPage<ForumTopic>>> listTopics({
    String? channel,
    String sort = 'hot',
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final headers = await _authHeader();
      if (headers == null) return ForumResult.failure('Not signed in', 401);

      final uri = Uri.parse('$_base/topics').replace(queryParameters: {
        'sort': sort,
        'page': '$page',
        'pageSize': '$pageSize',
        if (channel != null) 'channel': channel,
      });

      final response = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return ForumResult.failure(_messageFrom(response), response.statusCode);
      }
      final body = json.decode(response.body) as Map<String, dynamic>;
      final items = (body['items'] as List)
          .map((j) => ForumTopic.fromJson(j as Map<String, dynamic>))
          .toList();
      return ForumResult.success(ForumPage<ForumTopic>(
        total: body['total'] as int? ?? items.length,
        page: body['page'] as int? ?? page,
        pageSize: body['pageSize'] as int? ?? pageSize,
        items: items,
      ));
    } catch (e) {
      debugPrint('ForumService.listTopics error: $e');
      return ForumResult.failure('Network error', 0);
    }
  }

  /// Creates a topic. A topic is one short text plus a channel — there is no title.
  Future<ForumResult<int>> createTopic({required String text, String? channel}) async {
    try {
      final headers = await _authHeader();
      if (headers == null) return ForumResult.failure('Not signed in', 401);

      final response = await _client
          .post(
            Uri.parse('$_base/topics'),
            headers: headers,
            body: json.encode({'text': text.trim(), 'channel': channel}),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 201) {
        return ForumResult.failure(_messageFrom(response), response.statusCode);
      }
      final body = json.decode(response.body) as Map<String, dynamic>;
      return ForumResult.success(body['id'] as int, 201);
    } catch (e) {
      debugPrint('ForumService.createTopic error: $e');
      return ForumResult.failure('Network error', 0);
    }
  }

  /// Casts or changes a vote. Sending the same value again removes the vote.
  Future<ForumResult<int>> voteTopic(int topicId, int value) async {
    try {
      final headers = await _authHeader();
      if (headers == null) return ForumResult.failure('Not signed in', 401);

      final response = await _client
          .post(
            Uri.parse('$_base/topics/$topicId/vote'),
            headers: headers,
            body: json.encode({'value': value}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return ForumResult.failure(_messageFrom(response), response.statusCode);
      }
      final body = json.decode(response.body) as Map<String, dynamic>;
      return ForumResult.success(body['voteScore'] as int? ?? 0);
    } catch (e) {
      debugPrint('ForumService.voteTopic error: $e');
      return ForumResult.failure('Network error', 0);
    }
  }

  Future<ForumResult<bool>> deleteTopic(int topicId) async {
    try {
      final headers = await _authHeader();
      if (headers == null) return ForumResult.failure('Not signed in', 401);

      final response = await _client
          .delete(Uri.parse('$_base/topics/$topicId'), headers: headers)
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 204
          ? ForumResult.success(true, 204)
          : ForumResult.failure(_messageFrom(response), response.statusCode);
    } catch (e) {
      debugPrint('ForumService.deleteTopic error: $e');
      return ForumResult.failure('Network error', 0);
    }
  }

  Future<ForumResult<ForumPage<ForumAnswer>>> listAnswers(
    int topicId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final headers = await _authHeader();
      if (headers == null) return ForumResult.failure('Not signed in', 401);

      final uri = Uri.parse('$_base/topics/$topicId/answers')
          .replace(queryParameters: {'page': '$page', 'pageSize': '$pageSize'});
      final response = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return ForumResult.failure(_messageFrom(response), response.statusCode);
      }
      final body = json.decode(response.body) as Map<String, dynamic>;
      final items = (body['items'] as List)
          .map((j) => ForumAnswer.fromJson(j as Map<String, dynamic>))
          .toList();
      return ForumResult.success(ForumPage<ForumAnswer>(
        total: body['total'] as int? ?? items.length,
        page: body['page'] as int? ?? page,
        pageSize: body['pageSize'] as int? ?? pageSize,
        items: items,
      ));
    } catch (e) {
      debugPrint('ForumService.listAnswers error: $e');
      return ForumResult.failure('Network error', 0);
    }
  }

  Future<ForumResult<int>> createAnswer(int topicId, String text) async {
    try {
      final headers = await _authHeader();
      if (headers == null) return ForumResult.failure('Not signed in', 401);

      final response = await _client
          .post(
            Uri.parse('$_base/topics/$topicId/answers'),
            headers: headers,
            body: json.encode({'text': text.trim()}),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 201) {
        return ForumResult.failure(_messageFrom(response), response.statusCode);
      }
      final body = json.decode(response.body) as Map<String, dynamic>;
      return ForumResult.success(body['id'] as int, 201);
    } catch (e) {
      debugPrint('ForumService.createAnswer error: $e');
      return ForumResult.failure('Network error', 0);
    }
  }

  Future<ForumResult<bool>> deleteAnswer(int answerId) async {
    try {
      final headers = await _authHeader();
      if (headers == null) return ForumResult.failure('Not signed in', 401);

      final response = await _client
          .delete(Uri.parse('$_base/answers/$answerId'), headers: headers)
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 204
          ? ForumResult.success(true, 204)
          : ForumResult.failure(_messageFrom(response), response.statusCode);
    } catch (e) {
      debugPrint('ForumService.deleteAnswer error: $e');
      return ForumResult.failure('Network error', 0);
    }
  }

  /// Voice-to-text for the composer. Returns the transcript for the user to edit before
  /// posting — nothing is submitted on their behalf.
  ///
  /// Slow on CPU-only whisper (tens of seconds), so callers must show progress and fall
  /// back to typing when this returns a 503.
  Future<ForumResult<String>> transcribe(File audio) async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      if (token == null) return ForumResult.failure('Not signed in', 401);

      final request = http.MultipartRequest('POST', Uri.parse('$_base/transcribe'))
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('audio', audio.path));

      final streamed = await _client.send(request).timeout(const Duration(seconds: 300));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        return ForumResult.failure(_messageFrom(response), response.statusCode);
      }
      final body = json.decode(response.body) as Map<String, dynamic>;
      return ForumResult.success(body['text'] as String? ?? '');
    } catch (e) {
      debugPrint('ForumService.transcribe error: $e');
      return ForumResult.failure('Network error', 0);
    }
  }
}
