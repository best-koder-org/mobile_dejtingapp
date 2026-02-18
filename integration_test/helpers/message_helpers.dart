import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'test_config.dart';

/// Modular Messaging API helpers
/// REST messaging operations - composable for different chat flows

/// Send a message to a match via REST API
/// Contract: POST /api/messages → 200/201
/// Backend expects: {RecipientUserId: string, Text: string}
Future<Map<String, dynamic>> sendMessage(
  TestUser user,
  dynamic recipientUserId, {
  required String text,
}) async {
  // Backend expects string userId (Keycloak UUID)
  final recipientId = recipientUserId.toString();

  final response = await http.post(
    Uri.parse('${TestConfig.baseUrl}/api/messages'),
    headers: {
      'Content-Type': 'application/json',
      ...user.authHeaders,
    },
    body: jsonEncode({
      'recipientUserId': recipientId,
      'text': text,
    }),
  ).timeout(TestConfig.apiTimeout);

  if (response.statusCode != 201 && response.statusCode != 200) {
    throw Exception('Send message failed: ${response.statusCode} ${response.body}');
  }

  final data = jsonDecode(response.body);
  return Map<String, dynamic>.from(data['data'] ?? data);
}

/// Get conversation with a specific user
/// Contract: GET /api/messages/conversation/{otherUserId} → 200
/// Backend returns ApiResponse wrapper: {success, data: [...messages], ...}
Future<List<Map<String, dynamic>>> getConversation(
  TestUser user,
  dynamic otherUserId, {
  int? limit,
  int? offset,
}) async {
  final otherId = otherUserId.toString();
  final queryParams = <String, String>{};
  if (limit != null) queryParams['limit'] = limit.toString();
  if (offset != null) queryParams['offset'] = offset.toString();

  final uri = Uri.parse(
    '${TestConfig.baseUrl}/api/messages/conversation/$otherId'
  ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

  final response = await http.get(
    uri,
    headers: user.authHeaders,
  ).timeout(TestConfig.apiTimeout);

  if (response.statusCode != 200) {
    throw Exception('Get conversation failed: ${response.statusCode} ${response.body}');
  }

  final data = jsonDecode(response.body);
  // Unwrap ApiResponse: {success:true, data:[...]}
  final messages = data['data'] ?? data['messages'] ?? data;
  if (messages is List) return List<Map<String, dynamic>>.from(messages);
  return [];
}

/// Get all conversations for user
/// Contract: GET /api/messages/conversations → 200
Future<List<Map<String, dynamic>>> getConversations(TestUser user) async {
  final response = await http.get(
    Uri.parse('${TestConfig.baseUrl}/api/messages/conversations'),
    headers: user.authHeaders,
  ).timeout(TestConfig.apiTimeout);

  if (response.statusCode != 200) {
    throw Exception('Get conversations failed: ${response.statusCode} ${response.body}');
  }

  final data = jsonDecode(response.body);
  final conversations = data['data'] ?? data['conversations'] ?? data;
  if (conversations is List) return List<Map<String, dynamic>>.from(conversations);
  return [];
}

/// Mark message as read
/// Contract: POST /api/messages/{messageId}/read → 200
Future<void> markMessageRead(TestUser user, dynamic messageId) async {
  final response = await http.post(
    Uri.parse('${TestConfig.baseUrl}/api/messages/$messageId/read'),
    headers: user.authHeaders,
  ).timeout(TestConfig.apiTimeout);

  if (response.statusCode != 200 && response.statusCode != 204) {
    throw Exception('Mark read failed: ${response.statusCode}');
  }
}

/// Connect to SignalR messaging hub (for real-time testing)
/// This is optional - most tests can use REST API
Future<WebSocketChannel?> connectMessagingHub(TestUser user) async {
  if (!TestConfig.testMessaging) return null;

  try {
    final wsUrl = TestConfig.messagingServiceUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');

    final channel = WebSocketChannel.connect(
      Uri.parse('$wsUrl/messagingHub?access_token=${user.accessToken}'),
    );

    await channel.ready.timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw Exception('WebSocket connection timeout'),
    );

    return channel;
  } catch (e) {
    return null;
  }
}

/// Helper: Create match between two users (needed for messaging)
Future<void> createMatch(TestUser user1, TestUser user2) async {
  final uid1 = user1.profileId ?? int.tryParse(user1.userId ?? '');
  final uid2 = user2.profileId ?? int.tryParse(user2.userId ?? '');

  final response1 = await http.post(
    Uri.parse('${TestConfig.baseUrl}/api/swipes'),
    headers: {
      'Content-Type': 'application/json',
      ...user1.authHeaders,
    },
    body: jsonEncode({
      'userId': uid1,
      'targetUserId': uid2,
      'isLike': true,
    }),
  ).timeout(TestConfig.apiTimeout);

  final response2 = await http.post(
    Uri.parse('${TestConfig.baseUrl}/api/swipes'),
    headers: {
      'Content-Type': 'application/json',
      ...user2.authHeaders,
    },
    body: jsonEncode({
      'userId': uid2,
      'targetUserId': uid1,
      'isLike': true,
    }),
  ).timeout(TestConfig.apiTimeout);

  if (response1.statusCode < 200 || response1.statusCode >= 300) {
    throw Exception('Match creation failed (user1): ${response1.statusCode} ${response1.body}');
  }
  if (response2.statusCode < 200 || response2.statusCode >= 300) {
    throw Exception('Match creation failed (user2): ${response2.statusCode} ${response2.body}');
  }
}
