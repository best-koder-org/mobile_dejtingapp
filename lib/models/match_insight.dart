/// Data class representing the AI-generated insight for a match.
class MatchInsight {
  final int matchId;
  final double overallScore;
  final List<String> reasons;
  final List<String> frictions;
  final List<String>? growth;

  // T540+ Connection insight fields
  final ConnectionHook? connectionHook;
  final List<ConnectionSignal>? connectionSignals;
  final String? confidenceLevel;

  const MatchInsight({
    required this.matchId,
    required this.overallScore,
    required this.reasons,
    required this.frictions,
    this.growth,
    this.connectionHook,
    this.connectionSignals,
    this.confidenceLevel,
  });

  factory MatchInsight.fromJson(Map<String, dynamic> json) {
    final frictionRaw = (json['frictions'] ?? json['friction'] ?? const []) as List;

    // Parse connection hook
    ConnectionHook? hook;
    if (json['connectionHook'] != null && json['connectionHook'] is Map) {
      hook = ConnectionHook.fromJson(json['connectionHook'] as Map<String, dynamic>);
    }

    // Parse connection signals
    List<ConnectionSignal>? signals;
    if (json['connectionSignals'] != null && json['connectionSignals'] is List) {
      signals = (json['connectionSignals'] as List)
          .whereType<Map<String, dynamic>>()
          .map((s) => ConnectionSignal.fromJson(s))
          .toList();
    }

    return MatchInsight(
      matchId: json['matchId'] as int,
      overallScore: (json['overallScore'] as num).toDouble(),
      reasons: List<String>.from(json['reasons'] as List? ?? []),
      frictions: List<String>.from(frictionRaw),
      growth: json['growth'] != null
          ? List<String>.from(json['growth'] as List)
          : null,
      connectionHook: hook,
      connectionSignals: signals,
      confidenceLevel: json['confidenceLevel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'overallScore': overallScore,
      'reasons': reasons,
      'frictions': frictions,
      if (growth != null) 'growth': growth,
      if (connectionHook != null) 'connectionHook': connectionHook!.toJson(),
      if (connectionSignals != null)
        'connectionSignals': connectionSignals!.map((s) => s.toJson()).toList(),
      if (confidenceLevel != null) 'confidenceLevel': confidenceLevel,
    };
  }
}

/// The primary payload sent to the Flutter connection insight card.
class ConnectionHook {
  final String headline;
  final String body;
  final List<String> evidenceChips;
  final String suggestedPrompt;
  final String tone;
  final String confidenceLabel;

  const ConnectionHook({
    required this.headline,
    required this.body,
    required this.evidenceChips,
    required this.suggestedPrompt,
    required this.tone,
    required this.confidenceLabel,
  });

  factory ConnectionHook.fromJson(Map<String, dynamic> json) {
    return ConnectionHook(
      headline: json['headline'] as String? ?? '',
      body: json['body'] as String? ?? '',
      evidenceChips: List<String>.from(json['evidenceChips'] as List? ?? []),
      suggestedPrompt: json['suggestedPrompt'] as String? ?? '',
      tone: json['tone'] as String? ?? 'neutral',
      confidenceLabel: json['confidenceLabel'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'headline': headline,
        'body': body,
        'evidenceChips': evidenceChips,
        'suggestedPrompt': suggestedPrompt,
        'tone': tone,
        'confidenceLabel': confidenceLabel,
      };
}

/// A single signal that contributed to the connection insight.
class ConnectionSignal {
  final String type;
  final String title;
  final String summary;
  final List<String> evidence;
  final double confidence;
  final bool isCaution;

  const ConnectionSignal({
    required this.type,
    required this.title,
    required this.summary,
    required this.evidence,
    required this.confidence,
    required this.isCaution,
  });

  factory ConnectionSignal.fromJson(Map<String, dynamic> json) {
    return ConnectionSignal(
      type: json['type'] as String? ?? 'SharedInterest',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      evidence: List<String>.from(json['evidence'] as List? ?? []),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      isCaution: json['isCaution'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'summary': summary,
        'evidence': evidence,
        'confidence': confidence,
        'isCaution': isCaution,
      };
}

/// Parsed confidence level enum for display logic.
enum InsightConfidence {
  high,
  medium,
  low,
  insufficientData;

  static InsightConfidence fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'high':
        return InsightConfidence.high;
      case 'medium':
        return InsightConfidence.medium;
      case 'low':
        return InsightConfidence.low;
      default:
        return InsightConfidence.insufficientData;
    }
  }
}
