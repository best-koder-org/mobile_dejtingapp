import 'dart:convert';

import 'package:http/http.dart' as http;

import '../backend_url.dart';
import 'api_service.dart';

/// Model for a single compatibility question.
class CompatibilityQuestion {
  final String id;
  final String category;
  final String text;
  final List<String> options;

  const CompatibilityQuestion({
    required this.id,
    required this.category,
    required this.text,
    required this.options,
  });
}

/// Abstract interface for the compatibility-questions service.
///
/// Keeping it abstract makes it trivially mockable in tests without
/// code-generation — just extend and override the two methods.
abstract class CompatibilityService {
  /// Returns the list of compatibility questions to display.
  Future<List<CompatibilityQuestion>> fetchQuestions();

  /// Submits the user's answers (questionId → chosen option).
  /// Throws on network / server errors.
  Future<void> submitAnswers(Map<String, String> answers);
}

/// Default implementation that talks to the real backend
/// (MatchmakingService CompatibilityController via the YARP gateway).
///
/// Swap this out in tests by passing a mock to
/// [CompatibilityQuestionsScreen].
class DefaultCompatibilityService implements CompatibilityService {
  const DefaultCompatibilityService();

  /// Cache of questionId -> (optionLabel -> backend option value), populated by
  /// [fetchQuestions] so [submitAnswers] can translate chosen labels back into
  /// the integer values the backend expects. Static so a const instance can
  /// still retain state between fetch and submit.
  static final Map<String, Map<String, int>> _optionValues = {};

  @override
  Future<List<CompatibilityQuestion>> fetchQuestions() async {
    await AppState().initialize();
    final token = await AppState().getOrRefreshAuthToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('${ApiUrls.gateway}/api/compatibility/questions'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load questions (${response.statusCode})');
    }

    final List<dynamic> raw = jsonDecode(response.body) as List<dynamic>;
    _optionValues.clear();
    return raw.map((dynamic item) {
      final q = item as Map<String, dynamic>;
      final id = q['id'].toString();
      final options = (q['options'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      final labels = <String>[];
      final labelToValue = <String, int>{};
      for (final o in options) {
        final label = (o['label'] as String?) ?? '';
        final value = (o['value'] as num?)?.toInt() ?? 0;
        labels.add(label);
        labelToValue[label] = value;
      }
      _optionValues[id] = labelToValue;

      return CompatibilityQuestion(
        id: id,
        category: (q['category'] as String?) ?? '',
        text: (q['textEn'] as String?) ?? '',
        options: labels,
      );
    }).toList();
  }

  @override
  Future<void> submitAnswers(Map<String, String> answers) async {
    if (answers.isEmpty) return;

    await AppState().initialize();
    final token = await AppState().getOrRefreshAuthToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final payload = <Map<String, int>>[];
    answers.forEach((questionId, label) {
      final qid = int.tryParse(questionId);
      final value = _optionValues[questionId]?[label];
      if (qid != null && value != null) {
        payload.add({'questionId': qid, 'value': value});
      }
    });

    if (payload.isEmpty) return;

    final response = await http.post(
      Uri.parse('${ApiUrls.gateway}/api/compatibility/answers'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'answers': payload}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to submit answers (${response.statusCode})');
    }
  }
}
