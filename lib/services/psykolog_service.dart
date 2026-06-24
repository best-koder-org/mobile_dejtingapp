import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dejtingapp/config/environment.dart';
import 'package:dejtingapp/services/api_service.dart';

/// Session status from backend.
enum PsykologSessionStatus { active, completed, expired }

/// A psykolog session (no messages — they're purged after extraction).
class PsykologSessionInfo {
  final int id;
  final int sessionNumber;
  final DateTime startedAt;
  final DateTime? endedAt;
  final PsykologSessionStatus status;
  final int themeCount;

  const PsykologSessionInfo({
    required this.id,
    required this.sessionNumber,
    required this.startedAt,
    this.endedAt,
    required this.status,
    required this.themeCount,
  });

  factory PsykologSessionInfo.fromJson(Map<String, dynamic> j) =>
      PsykologSessionInfo(
        id: j['id'] as int,
        sessionNumber: j['sessionNumber'] as int,
        startedAt: DateTime.parse(j['startedAt'] as String),
        endedAt: j['endedAt'] != null ? DateTime.parse(j['endedAt'] as String) : null,
        status: _parseStatus(j['status'] as String? ?? 'active'),
        themeCount: j['themeCount'] as int? ?? 0,
      );

  static PsykologSessionStatus _parseStatus(String s) {
    switch (s.toLowerCase()) {
      case 'completed': return PsykologSessionStatus.completed;
      case 'expired': return PsykologSessionStatus.expired;
      default: return PsykologSessionStatus.active;
    }
  }
}

/// An extracted psychological theme.
class PsykologTheme {
  final int id;
  final String label;
  final double intensity;
  final String axis;
  final DateTime createdAt;

  const PsykologTheme({
    required this.id,
    required this.label,
    required this.intensity,
    required this.axis,
    required this.createdAt,
  });

  factory PsykologTheme.fromJson(Map<String, dynamic> j) => PsykologTheme(
        id: j['id'] as int,
        label: j['label'] as String,
        intensity: (j['intensity'] as num).toDouble(),
        axis: j['axis'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

/// Flutter API client for the AI Psykolog feature.
class PsykologService {
  PsykologService._();
  static final PsykologService instance = PsykologService._();

  String get _base => '${EnvironmentConfig.settings.gatewayUrl}/api/psykolog';

  Future<Map<String, String>> _headers() async {
    final token = await AppState().getOrRefreshAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Start a new session. Returns null if monthly limit reached (429).
  Future<PsykologSessionInfo?> startSession() async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/sessions'),
        headers: await _headers(),
      );
      if (resp.statusCode == 429) return null;
      if (resp.statusCode != 200) return null;
      return PsykologSessionInfo.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Send a message and get the assistant reply. Returns null on error/limit.
  Future<String?> sendMessage(int sessionId, String content) async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/sessions/$sessionId/messages'),
        headers: await _headers(),
        body: jsonEncode({'content': content}),
      );
      if (resp.statusCode == 429 || resp.statusCode != 200) return null;
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      return body['content'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// End a session and trigger theme extraction.
  Future<PsykologSessionInfo?> endSession(int sessionId) async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/sessions/$sessionId/end'),
        headers: await _headers(),
      );
      if (resp.statusCode != 200) return null;
      return PsykologSessionInfo.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Fetch list of past sessions.
  Future<List<PsykologSessionInfo>> getSessions() async {
    try {
      final resp = await http.get(
        Uri.parse('$_base/sessions'),
        headers: await _headers(),
      );
      if (resp.statusCode != 200) return [];
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => PsykologSessionInfo.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch extracted themes for the current user.
  Future<List<PsykologTheme>> getThemes() async {
    try {
      final resp = await http.get(
        Uri.parse('$_base/themes'),
        headers: await _headers(),
      );
      if (resp.statusCode != 200) return [];
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => PsykologTheme.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
