import 'dart:convert';
import 'package:http/http.dart' as http;
import 'test_config.dart';

/// Modular Safety API helpers
/// Block/unblock operations against safety-service

/// Block a user
/// Contract: POST /api/safety/block → 201
/// Backend expects: {blockedUserId: string (Keycloak UUID)}
Future<void> blockUser(TestUser user, dynamic targetUserId) async {
  final response = await http.post(
    Uri.parse('${TestConfig.baseUrl}/api/safety/block'),
    headers: {
      'Content-Type': 'application/json',
      ...user.authHeaders,
    },
    body: jsonEncode({
      'blockedUserId': targetUserId.toString(),
    }),
  ).timeout(TestConfig.apiTimeout);

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception('Block user failed: ${response.statusCode} ${response.body}');
  }
}

/// Unblock a user
/// Contract: DELETE /api/safety/block/{blockedUserId} → 200/204
Future<void> unblockUser(TestUser user, dynamic targetUserId) async {
  final response = await http.delete(
    Uri.parse('${TestConfig.baseUrl}/api/safety/block/${targetUserId.toString()}'),
    headers: user.authHeaders,
  ).timeout(TestConfig.apiTimeout);

  if (response.statusCode != 200 && response.statusCode != 204) {
    throw Exception('Unblock user failed: ${response.statusCode}');
  }
}

/// Get list of blocked users
/// Contract: GET /api/safety/block → 200 with array of BlockedUserResponse
Future<List<dynamic>> getBlockedUsers(TestUser user) async {
  final response = await http.get(
    Uri.parse('${TestConfig.baseUrl}/api/safety/block'),
    headers: user.authHeaders,
  ).timeout(TestConfig.apiTimeout);

  if (response.statusCode != 200) {
    throw Exception('Get blocked users failed: ${response.statusCode}');
  }

  final data = jsonDecode(response.body);
  if (data is List) return data;
  final inner = data['data'] ?? data['blockedUserIds'] ?? data;
  if (inner is List) return inner;
  return [];
}

/// Report a user (if implemented)
/// Contract: POST /api/safety/report → 200
Future<void> reportUser(
  TestUser user,
  dynamic targetUserId, {
  required String reason,
  String? details,
}) async {
  final response = await http.post(
    Uri.parse('${TestConfig.baseUrl}/api/safety/report'),
    headers: {
      'Content-Type': 'application/json',
      ...user.authHeaders,
    },
    body: jsonEncode({
      'reportedUserId': targetUserId.toString(),
      'reason': reason,
      if (details != null) 'details': details,
    }),
  ).timeout(TestConfig.apiTimeout);

  if (response.statusCode != 200 && response.statusCode != 201) {
    if (response.statusCode == 404) return;
    throw Exception('Report user failed: ${response.statusCode}');
  }
}
