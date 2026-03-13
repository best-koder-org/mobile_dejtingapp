import 'dart:convert';
import 'package:http/http.dart' as http;
import 'test_config.dart';

class SafetyHelpers {
  /// Block a user
  /// Contract: POST /api/safety/block → 200/201/500
  /// DTO: { blockedUserId: string, reason?: string }
  /// Note: 500 is a known backend bug (CreatedAtAction route), block still succeeds
  static Future<http.Response> blockUser(String token, String targetUserId, {String? reason}) async {
    final response = await http.post(
      Uri.parse('${TestConfig.baseUrl}/api/safety/block'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'blockedUserId': targetUserId,
        if (reason != null) 'reason': reason,
      }),
    );
    return response;
  }

  /// Unblock a user  
  /// Contract: DELETE /api/safety/block/{blockedUserId} → 204
  static Future<http.Response> unblockUser(String token, String blockedUserId) async {
    final response = await http.delete(
      Uri.parse('${TestConfig.baseUrl}/api/safety/block/$blockedUserId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response;
  }

  /// Get blocked users list
  /// Contract: GET /api/safety/block → 200 (returns JSON array)
  static Future<http.Response> getBlockedUsers(String token) async {
    final response = await http.get(
      Uri.parse('${TestConfig.baseUrl}/api/safety/block'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response;
  }

  /// Check if a specific user is blocked
  /// Contract: GET /api/safety/block/{userId} → 200 { userId, isBlocked }
  static Future<http.Response> isUserBlocked(String token, String targetUserId) async {
    final response = await http.get(
      Uri.parse('${TestConfig.baseUrl}/api/safety/block/$targetUserId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response;
  }

  /// Report a user
  /// Contract: POST /api/safety/reports → 201
  /// DTO: { reportedUserId, reportType, description, contextData? }
  static Future<http.Response> reportUser(String token, String reportedUserId, String reportType, String description, {String? contextData}) async {
    final response = await http.post(
      Uri.parse('${TestConfig.baseUrl}/api/safety/reports'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'reportedUserId': reportedUserId,
        'reportType': reportType,
        'description': description,
        if (contextData != null) 'contextData': contextData,
      }),
    );
    return response;
  }

  /// Check mutual block between two users (service-to-service, no auth required)
  /// Contract: GET /api/safety/block/mutual-check?userId1={}&userId2={} → 200
  static Future<http.Response> mutualBlockCheck(String userId1, String userId2) async {
    final response = await http.get(
      Uri.parse('${TestConfig.baseUrl}/api/safety/block/mutual-check?userId1=$userId1&userId2=$userId2'),
    );
    return response;
  }
}
