import 'dart:convert';
import 'package:http/http.dart' as http;
import 'test_config.dart';

/// Modular Swipe/Matching API helpers
/// Atomic matching operations - easily composed into different discovery flows

/// Get candidate profiles from matchmaking service
/// Contract: GET /api/matchmaking/profiles/{userId} → 200 with profile data
Future<List<Map<String, dynamic>>> getCandidates(TestUser user) async {
  final profileId = user.profileId ?? user.userId;
  final response = await http.get(
    Uri.parse('${TestConfig.baseUrl}/api/matchmaking/profiles/$profileId'),
    headers: user.authHeaders,
  ).timeout(TestConfig.apiTimeout);

  if (response.statusCode != 200) {
    throw Exception('Get candidates failed: ${response.statusCode} ${response.body}');
  }

  final data = jsonDecode(response.body);
  // Response may be a single profile or list — normalize to list
  if (data is List) return List<Map<String, dynamic>>.from(data);
  if (data is Map && data.containsKey('data')) {
    final inner = data['data'];
    if (inner is List) return List<Map<String, dynamic>>.from(inner);
    return [Map<String, dynamic>.from(inner)];
  }
  return [Map<String, dynamic>.from(data)];
}

/// Swipe on a candidate
/// Contract: POST /api/swipes → 200, returns match if mutual like
/// Note: SwipeService expects {UserId: int, TargetUserId: int, IsLike: bool}
Future<Map<String, dynamic>> swipeOnUser(
  TestUser user,
  dynamic targetUserId, {
  required bool isLike,
}) async {
  final response = await http.post(
    Uri.parse('${TestConfig.baseUrl}/api/swipes'),
    headers: {
      'Content-Type': 'application/json',
      ...user.authHeaders,
    },
    body: jsonEncode({
      'userId': user.profileId ?? int.tryParse(user.userId ?? ''),
      'targetUserId': targetUserId is int ? targetUserId : int.tryParse(targetUserId.toString()),
      'isLike': isLike,
    }),
  ).timeout(TestConfig.apiTimeout);

  if (response.statusCode != 201 && response.statusCode != 200) {
    throw Exception('Swipe failed: ${response.statusCode} ${response.body}');
  }

  final data = jsonDecode(response.body);
  // Unwrap ApiResponse if wrapped
  return Map<String, dynamic>.from(data['data'] ?? data);
}

/// Get all matches for user
/// Contract: GET /api/matchmaking/matches/{userId} → 200 with array
Future<List<Map<String, dynamic>>> getMatches(TestUser user) async {
  final profileId = user.profileId ?? user.userId;
  final response = await http.get(
    Uri.parse('${TestConfig.baseUrl}/api/matchmaking/matches/$profileId'),
    headers: user.authHeaders,
  ).timeout(TestConfig.apiTimeout);

  if (response.statusCode != 200) {
    throw Exception('Get matches failed: ${response.statusCode} ${response.body}');
  }

  final data = jsonDecode(response.body);
  if (data is List) return List<Map<String, dynamic>>.from(data);
  // Unwrap {Matches: [...]} or {data: [...]}
  final inner = data['Matches'] ?? data['matches'] ?? data['data'] ?? data;
  if (inner is List) return List<Map<String, dynamic>>.from(inner);
  return [];
}

/// Get swipe history (for testing)
/// Contract: GET /api/swipes/user/{userId} → 200 with swipe records
Future<List<Map<String, dynamic>>> getSwipeHistory(TestUser user) async {
  final profileId = user.profileId ?? user.userId;
  final response = await http.get(
    Uri.parse('${TestConfig.baseUrl}/api/swipes/user/$profileId'),
    headers: user.authHeaders,
  ).timeout(TestConfig.apiTimeout);

  if (response.statusCode != 200) {
    throw Exception('Get history failed: ${response.statusCode} ${response.body}');
  }

  final data = jsonDecode(response.body);
  if (data is List) return List<Map<String, dynamic>>.from(data);
  final inner = data['data'] ?? data['swipes'] ?? data;
  if (inner is List) return List<Map<String, dynamic>>.from(inner);
  return [];
}
