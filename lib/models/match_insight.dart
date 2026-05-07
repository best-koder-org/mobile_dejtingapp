/// Data class representing the AI-generated insight for a match.
class MatchInsight {
  final int matchId;
  final double overallScore;
  final List<String> reasons;
  final List<String> friction;
  final List<String>? growth;

  const MatchInsight({
    required this.matchId,
    required this.overallScore,
    required this.reasons,
    required this.friction,
    this.growth,
  });

  factory MatchInsight.fromJson(Map<String, dynamic> json) {
    return MatchInsight(
      matchId: json['matchId'] as int,
      overallScore: (json['overallScore'] as num).toDouble(),
      reasons: List<String>.from(json['reasons'] as List),
      friction: List<String>.from(json['friction'] as List),
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
      'friction': friction,
      if (growth != null) 'growth': growth,
    };
  }
}
