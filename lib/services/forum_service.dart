import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../backend_url.dart';

/// Forum post model
class ForumPost {
  final int id;
  final String authorId;
  final String title;
  final String body;
  final String category;
  final DateTime createdAt;
  final DateTime? editedAt;
  final int voteScore;
  final int commentCount;

  const ForumPost({
    required this.id,
    required this.authorId,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    this.editedAt,
    required this.voteScore,
    required this.commentCount,
  });

  factory ForumPost.fromJson(Map<String, dynamic> j) => ForumPost(
        id: j['id'] as int,
        authorId: j['authorId'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        category: j['category'] as String? ?? 'general',
        createdAt: DateTime.parse(j['createdAt'] as String),
        editedAt: j['editedAt'] != null
            ? DateTime.parse(j['editedAt'] as String)
            : null,
        voteScore: j['voteScore'] as int? ?? 0,
        commentCount: j['commentCount'] as int? ?? 0,
      );

  ForumPost copyWith({int? voteScore}) => ForumPost(
        id: id,
        authorId: authorId,
        title: title,
        body: body,
        category: category,
        createdAt: createdAt,
        editedAt: editedAt,
        voteScore: voteScore ?? this.voteScore,
        commentCount: commentCount,
      );
}

/// Service for the Community forum feature.
/// All calls go through YARP: GET/POST /api/forum
class ForumService {
  static final ForumService _instance = ForumService._();
  factory ForumService() => _instance;
  ForumService._();

  static String get _base => '${ApiUrls.gateway}/api/forum';

  Future<Map<String, String>?> _authHeader() async {
    final token = await AppState().getOrRefreshAuthToken();
    if (token == null) return null;
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  }

  /// Fetch paginated posts, optionally filtered by category.
  Future<List<ForumPost>> listPosts({
    String? category,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final headers = await _authHeader();
      if (headers == null) return [];

      var uri = Uri.parse(_base).replace(queryParameters: {
        'page': '$page',
        'pageSize': '$pageSize',
        if (category != null) 'category': category,
      });

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List;
        return list
            .map((j) => ForumPost.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      debugPrint('listPosts failed (${response.statusCode}): ${response.body}');
      return [];
    } catch (e) {
      debugPrint('listPosts error: $e');
      return [];
    }
  }

  /// Create a new post. Returns the created post id or null on failure.
  Future<int?> createPost({
    required String title,
    required String body,
    String category = 'general',
  }) async {
    try {
      final headers = await _authHeader();
      if (headers == null) return null;

      final response = await http
          .post(
            Uri.parse(_base),
            headers: headers,
            body: json.encode({'title': title, 'body': body, 'category': category}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['id'] as int?;
      }
      debugPrint('createPost failed (${response.statusCode}): ${response.body}');
      return null;
    } catch (e) {
      debugPrint('createPost error: $e');
      return null;
    }
  }

  /// Vote on a post (+1 upvote, -1 downvote). Returns new score or null.
  Future<int?> vote(int postId, int value) async {
    try {
      final headers = await _authHeader();
      if (headers == null) return null;

      final response = await http
          .post(
            Uri.parse('$_base/$postId/vote'),
            headers: headers,
            body: json.encode({'value': value}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['voteScore'] as int?;
      }
      debugPrint('vote failed (${response.statusCode}): ${response.body}');
      return null;
    } catch (e) {
      debugPrint('vote error: $e');
      return null;
    }
  }

  /// Soft-delete own post.
  Future<bool> deletePost(int postId) async {
    try {
      final headers = await _authHeader();
      if (headers == null) return false;

      final response = await http
          .delete(Uri.parse('$_base/$postId'), headers: headers)
          .timeout(const Duration(seconds: 8));

      return response.statusCode == 204;
    } catch (e) {
      debugPrint('deletePost error: $e');
      return false;
    }
  }
}
