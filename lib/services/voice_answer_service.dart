import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'api_service.dart';
import '../backend_url.dart';

/// Service for voice answer questions and uploads during onboarding.
///
/// Endpoints:
///   GET  /api/voice-answers/questions?flavorId=voice  → question pool
///   POST /api/voice-answers/{questionId}              → upload answer audio
///   GET  /api/voice-answers/my                        → current user's answers
///   GET  /api/voice-answers/{answerId}/audio           → stream audio
class VoiceAnswerService {
  static final VoiceAnswerService _instance = VoiceAnswerService._();
  factory VoiceAnswerService() => _instance;
  VoiceAnswerService._();

  /// Fetch the question pool for a flavor.
  Future<List<VoiceQuestion>> getQuestions({String flavorId = 'voice'}) async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      if (token == null) return [];

      final uri = Uri.parse(
        '${ApiUrls.gateway}/api/voice-answers/questions?flavorId=$flavorId',
      );
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List;
        return list.map((j) => VoiceQuestion.fromJson(j as Map<String, dynamic>)).toList();
      }

      debugPrint('getQuestions failed (${response.statusCode}): ${response.body}');
      return [];
    } catch (e) {
      debugPrint('getQuestions error: $e');
      return [];
    }
  }

  /// Upload a recorded voice answer for a specific question.
  /// Returns the answer id on success, null on failure.
  Future<int?> uploadAnswer({
    required int questionId,
    required String filePath,
    required double durationSeconds,
  }) async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      if (token == null) return null;

      final file = File(filePath);
      if (!await file.exists()) return null;

      final uri = Uri.parse('${ApiUrls.gateway}/api/voice-answers/$questionId');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['duration'] = durationSeconds.toStringAsFixed(1)
        ..files.add(await http.MultipartFile.fromPath(
          'audio',
          filePath,
          filename: p.basename(filePath),
        ));

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['id'] as int?;
      }

      debugPrint('uploadAnswer failed (${response.statusCode}): ${response.body}');
      return null;
    } catch (e) {
      debugPrint('uploadAnswer error: $e');
      return null;
    }
  }

  /// Get the current user's voice answers count.
  Future<int> getMyAnswerCount() async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      if (token == null) return 0;

      final uri = Uri.parse('${ApiUrls.gateway}/api/voice-answers/my');
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['count'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('getMyAnswerCount error: $e');
      return 0;
    }
  }


  /// Fetch another user's voice answers for discovery cards.
  /// GET /api/voice-answers/user/{userId}
  Future<List<VoiceAnswerPreview>> getUserAnswers(int userId) async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      if (token == null) return [];

      final uri = Uri.parse(
        '${ApiUrls.gateway}/api/voice-answers/user/$userId',
      );
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final list = data['answers'] as List? ?? [];
        return list
            .map((j) => VoiceAnswerPreview.fromJson(j as Map<String, dynamic>))
            .toList();
      }

      debugPrint('getUserAnswers failed (\${response.statusCode}): \${response.body}');
      return [];
    } catch (e) {
      debugPrint('getUserAnswers error: $e');
      return [];
    }
  }

  /// Build the audio URL for a voice answer.
  String audioUrl(int answerId) =>
      '${ApiUrls.gateway}/api/voice-answers/$answerId/audio';
}

/// Voice question data model.
class VoiceQuestion {
  final int id;
  final String questionText;
  final String? questionTextEn;
  final int questionOrder;

  const VoiceQuestion({
    required this.id,
    required this.questionText,
    this.questionTextEn,
    required this.questionOrder,
  });

  factory VoiceQuestion.fromJson(Map<String, dynamic> json) => VoiceQuestion(
        id: json['id'] as int,
        questionText: json['questionText'] as String,
        questionTextEn: json['questionTextEn'] as String?,
        questionOrder: json['questionOrder'] as int,
      );
}

/// Preview of another user's voice answer (for discovery cards).
class VoiceAnswerPreview {
  final int id;
  final int questionId;
  final String questionText;
  final String? questionTextEn;
  final double durationSeconds;
  final String audioUrl;

  const VoiceAnswerPreview({
    required this.id,
    required this.questionId,
    required this.questionText,
    this.questionTextEn,
    required this.durationSeconds,
    required this.audioUrl,
  });

  factory VoiceAnswerPreview.fromJson(Map<String, dynamic> json) =>
      VoiceAnswerPreview(
        id: json['id'] as int,
        questionId: json['questionId'] as int,
        questionText: json['questionText'] as String? ?? '',
        questionTextEn: json['questionTextEn'] as String?,
        durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 0,
        audioUrl: json['audioUrl'] as String? ?? '',
      );
}
