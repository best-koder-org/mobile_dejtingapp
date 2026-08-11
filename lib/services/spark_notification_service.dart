import 'package:http/http.dart' as http;
import 'dart:convert';
import '../backend_url.dart';
import 'api_service.dart';

/// Polling service that fetches unread spark count from GET /api/notifications/sparks.
class SparkNotificationService {
  /// Fetch the number of unread sparks from the backend.
  /// Returns 0 on any error (silent fail).
  Future<int> fetchUnreadCount() async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      if (token == null) return 0;

      final uri = Uri.parse('${ApiUrls.gateway}/api/notifications/sparks');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['sparkNotificationsEnabled'] == false) return 0;
        return (body['count'] as int?) ?? 0;
      }
      return 0;
    } catch (_) {
      return 0; // Silently ignore
    }
  }
}
