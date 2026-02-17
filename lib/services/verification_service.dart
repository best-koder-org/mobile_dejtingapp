import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../config/environment.dart';
import 'api_service.dart' show AppState;

/// Service for identity verification via face comparison.
/// Calls photo-service POST /api/verification/submit and GET /api/verification/status.
class VerificationService {
  String get _baseUrl => EnvironmentConfig.settings.photoServiceUrl;

  /// Submit a selfie for verification against the user's profile photo.
  /// Returns a [VerificationResult] with the decision and details.
  Future<VerificationResult> submitSelfie(File selfieFile) async {
    final token = await AppState().getOrRefreshAuthToken();
    if (token == null) {
      return VerificationResult(
        decision: VerificationDecision.error,
        similarity: 0,
        message: 'Not authenticated. Please log in.',
      );
    }

    try {
      final uri = Uri.parse('$_baseUrl/api/verification/submit');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      final mimeType = lookupMimeType(selfieFile.path) ?? 'image/jpeg';
      final parts = mimeType.split('/');
      request.files.add(await http.MultipartFile.fromPath(
        'selfie',
        selfieFile.path,
        contentType: MediaType(parts[0], parts[1]),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return VerificationResult.fromJson(data);
      } else if (response.statusCode == 429) {
        return VerificationResult(
          decision: VerificationDecision.rateLimited,
          similarity: 0,
          message: 'Too many attempts today. Try again tomorrow.',
        );
      } else {
        return VerificationResult(
          decision: VerificationDecision.error,
          similarity: 0,
          message: 'Verification failed (${response.statusCode}). Try again later.',
        );
      }
    } catch (e) {
      return VerificationResult(
        decision: VerificationDecision.error,
        similarity: 0,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  /// Get the current verification status for the logged-in user.
  Future<VerificationStatus?> getStatus() async {
    final token = await AppState().getOrRefreshAuthToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/verification/status'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return VerificationStatus.fromJson(json.decode(response.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

enum VerificationDecision {
  verified,
  pendingReview,
  rejected,
  rateLimited,
  error,
}

class VerificationResult {
  final VerificationDecision decision;
  final double similarity;
  final String message;
  final int? attemptId;

  VerificationResult({
    required this.decision,
    required this.similarity,
    required this.message,
    this.attemptId,
  });

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      decision: _parseDecision(json['decision'] as String? ?? ''),
      similarity: (json['similarityScore'] as num?)?.toDouble() ?? 0,
      message: json['message'] as String? ?? '',
      attemptId: json['attemptId'] as int?,
    );
  }

  static VerificationDecision _parseDecision(String value) {
    switch (value.toLowerCase()) {
      case 'verified':
        return VerificationDecision.verified;
      case 'pendingreview':
        return VerificationDecision.pendingReview;
      case 'rejected':
        return VerificationDecision.rejected;
      case 'ratelimited':
        return VerificationDecision.rateLimited;
      default:
        return VerificationDecision.error;
    }
  }

  bool get isVerified => decision == VerificationDecision.verified;
}

class VerificationStatus {
  final bool isVerified;
  final String? lastAttemptResult;
  final DateTime? lastAttemptAt;
  final int attemptsToday;

  VerificationStatus({
    required this.isVerified,
    this.lastAttemptResult,
    this.lastAttemptAt,
    required this.attemptsToday,
  });

  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    return VerificationStatus(
      isVerified: json['isVerified'] as bool? ?? false,
      lastAttemptResult: json['lastAttemptResult'] as String?,
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.tryParse(json['lastAttemptAt'] as String)
          : null,
      attemptsToday: json['attemptsToday'] as int? ?? 0,
    );
  }

  bool get canAttempt => attemptsToday < 3 && !isVerified;
}
