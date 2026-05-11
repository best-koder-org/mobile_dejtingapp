/// Data class representing the AI-generated insight for a match.
class MatchInsight {
  final int matchId;
  final double overallScore;
  final List<String> reasons;
  final List<String> frictions;
  final List<String>? growth;

  const MatchInsight({
    required this.matchId,
    required this.overallScore,
    required this.reasons,
    required this.frictions,
    this.growth,
  });

  factory MatchInsight.fromJson(Map<String, dynamic> json) {
    // Backend returns `frictions` (plural). Accept `friction` (singular) as a
    // tolerant fallback for older mocks and tests.
    final frictionRaw = (json['frictions'] ?? json['friction'] ?? const []) as List;
    return MatchInsight(
      matchId: json['matchId'] as int,
      overallScore: (json['overallScore'] as num).toDouble(),
      reasons: List<String>.from(json['reasons'] as List),
      frictions: List<String>.from(frictionRaw),
      growth: json['growth'] != null
          ? List<String>.from(json['growth'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'overallScore': overallScore,
      'reasons': reasons,
      'frictions': frictions,
      if (growth != null) 'growth': growth,
    };
  }
}
