import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dejtingapp/backend_url.dart';
import 'package:dejtingapp/services/api_service.dart';

/// Feedback trends data from MatchmakingService.
class FeedbackTrends {
  final int totalFeedbacks;
  final double avgOverallRating;
  final double avgChemistryRating;
  final double avgConversationRating;
  final int wouldMeetAgainCount;
  final double? previousAvgOverall;
  final double improvementPercent;

  const FeedbackTrends({
    required this.totalFeedbacks,
    required this.avgOverallRating,
    required this.avgChemistryRating,
    required this.avgConversationRating,
    required this.wouldMeetAgainCount,
    this.previousAvgOverall,
    required this.improvementPercent,
  });

  factory FeedbackTrends.fromJson(Map<String, dynamic> j) => FeedbackTrends(
    totalFeedbacks: j['totalFeedbacks'] as int? ?? 0,
    avgOverallRating: (j['avgOverallRating'] as num?)?.toDouble() ?? 0,
    avgChemistryRating: (j['avgChemistryRating'] as num?)?.toDouble() ?? 0,
    avgConversationRating: (j['avgConversationRating'] as num?)?.toDouble() ?? 0,
    wouldMeetAgainCount: j['wouldMeetAgainCount'] as int? ?? 0,
    previousAvgOverall: (j['previousAvgOverall'] as num?)?.toDouble(),
    improvementPercent: (j['improvementPercent'] as num?)?.toDouble() ?? 0,
  );
}

/// Fetches feedback trend data from MatchmakingService feedback/trends endpoint.
class FeedbackTrendsService {
  static final FeedbackTrendsService instance = FeedbackTrendsService._();
  FeedbackTrendsService._();

  Future<FeedbackTrends?> getTrends() async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      final url = Uri.parse(
          '${ApiUrls.matchmakingService}/api/matchmaking/feedback/trends');

      final resp = await http.get(url, headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      if (resp.statusCode == 200) {
        return FeedbackTrends.fromJson(
            jsonDecode(resp.body) as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
