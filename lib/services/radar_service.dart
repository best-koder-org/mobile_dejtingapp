import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dejtingapp/backend_url.dart';
import 'package:dejtingapp/services/api_service.dart';

/// Radar profile data from MatchmakingService.
class RadarProfileData {
  final String keycloakId;
  final double emotionalStability;
  final double socialEnergy;
  final double openness;
  final double warmth;
  final double lifeStructure;
  final double intimacyComfort;
  final double conflictStyle;
  final double confidence;
  final DateTime updatedAt;
  final Map<String, dynamic>? previousAxes; // T631: before/after comparison

  const RadarProfileData({
    required this.keycloakId,
    required this.emotionalStability,
    required this.socialEnergy,
    required this.openness,
    required this.warmth,
    required this.lifeStructure,
    required this.intimacyComfort,
    required this.conflictStyle,
    required this.confidence,
    required this.updatedAt,
    this.previousAxes,
  });

  factory RadarProfileData.fromJson(Map<String, dynamic> j) => RadarProfileData(
    keycloakId: j['keycloakId'] as String? ?? '',
    emotionalStability: (j['axes']['emotionalStability'] as num?)?.toDouble() ?? 0.5,
    socialEnergy: (j['axes']['socialEnergy'] as num?)?.toDouble() ?? 0.5,
    openness: (j['axes']['openness'] as num?)?.toDouble() ?? 0.5,
    warmth: (j['axes']['warmth'] as num?)?.toDouble() ?? 0.5,
    lifeStructure: (j['axes']['lifeStructure'] as num?)?.toDouble() ?? 0.5,
    intimacyComfort: (j['axes']['intimacyComfort'] as num?)?.toDouble() ?? 0.5,
    conflictStyle: (j['axes']['conflictStyle'] as num?)?.toDouble() ?? 0.5,
    confidence: (j['confidence'] as num?)?.toDouble() ?? 0.3,
    updatedAt: j['updatedAt'] != null
        ? DateTime.parse(j['updatedAt'] as String)
        : DateTime.now(),
    previousAxes: j['previousAxes'] as Map<String, dynamic>?,
  );

  List<double> get values => [
    emotionalStability, socialEnergy, openness, warmth,
    lifeStructure, intimacyComfort, conflictStyle,
  ];
}

/// Fetches radar profile data from MatchmakingService.
class RadarService {
  static final RadarService instance = RadarService._();
  RadarService._();

  Future<RadarProfileData?> getMyProfile() async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      final url = Uri.parse(
          '${ApiUrls.matchmakingService}/api/compatibility/radar/me');

      final resp = await http.get(url, headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      if (resp.statusCode == 200) {
        return RadarProfileData.fromJson(
            jsonDecode(resp.body) as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
