import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dejtingapp/backend_url.dart';
import 'package:dejtingapp/services/api_service.dart';

/// Service for submitting feedback and fetching reputation data.
class ReputationService {
  static final ReputationService instance = ReputationService._();
  ReputationService._();

  Future<Map<String, dynamic>?> submitFeedback({
    required String targetKeycloakId,
    required String matchId,
    required int overallRating,
    List<String> selectedTraits = const [],
    String? freeformNote,
    String feedbackType = 'chat',
  }) async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      final url = Uri.parse(
          '${ApiUrls.gateway}/api/reputation/feedback');

      final resp = await http.post(url, headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      }, body: jsonEncode({
        'keycloakId': AppState().userId ?? '',
        'targetKeycloakId': targetKeycloakId,
        'matchId': matchId,
        'overallRating': overallRating,
        'selectedTraits': selectedTraits,
        'freeformNote': freeformNote,
        'feedbackType': feedbackType,
      }));

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTraits(String keycloakId) async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      final url = Uri.parse(
          '${ApiUrls.gateway}/api/reputation/traits/$keycloakId');

      final resp = await http.get(url, headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      });

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
