import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../backend_url.dart';
import '../models/onboarding_data.dart';
import 'api_service.dart';

/// Submits collected onboarding wizard data to UserService.
///
/// Calls up to 5 wizard PATCH endpoints in sequence:
///   PATCH /api/wizard/step/1  → BasicInfo  (name, dob, gender)
///   PATCH /api/wizard/step/2  → Preferences (ages, distance, bio)
///   PATCH /api/wizard/step/3  → Photos     (photo URLs)
///   PATCH /api/wizard/step/4  → Identity   (orientation, relationship goals) — optional
///   PATCH /api/wizard/step/5  → AboutMe    (interests, lifestyle, work, edu)  — optional
///
/// Returns `null` on success, or a human-readable error message.
class OnboardingApiService {
  /// Submit all wizard data to UserService.
  /// Returns a human-readable error message, or `null` on success.
  static Future<String?> submitAll(OnboardingData data) async {
    final token = AppState().authToken;
    if (token == null) {
      return 'Not authenticated — please log in again.';
    }

    final base = ApiUrls.userService;
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // Step 1: Basic Info (required)
    final step1 = await _patch(
      '$base/api/wizard/step/1',
      headers,
      data.toBasicInfoPayload(),
    );
    if (step1 != null) return 'Step 1 (profile): $step1';

    // Step 2: Preferences (required)
    final step2 = await _patch(
      '$base/api/wizard/step/2',
      headers,
      data.toPreferencesPayload(),
    );
    if (step2 != null) return 'Step 2 (preferences): $step2';

    // Step 3: Photos (only if we have any)
    if (data.photoUrls.isNotEmpty) {
      final step3 = await _patch(
        '$base/api/wizard/step/3',
        headers,
        data.toPhotosPayload(),
      );
      if (step3 != null) return 'Step 3 (photos): $step3';
    }

    // Step 4: Identity — orientation + relationship goals (only if user filled them)
    if (data.hasIdentityData) {
      final step4 = await _patch(
        '$base/api/wizard/step/4',
        headers,
        data.toIdentityPayload(),
      );
      if (step4 != null) {
        // Non-blocking: log but don't fail the whole submission
        debugPrint('⚠️ Step 4 (identity) failed: $step4 — continuing anyway');
      }
    }

    // Step 5: About Me — interests, lifestyle, work, education (only if user filled them)
    if (data.hasAboutMeData) {
      final step5 = await _patch(
        '$base/api/wizard/step/5',
        headers,
        data.toAboutMePayload(),
      );
      if (step5 != null) {
        // Non-blocking: log but don't fail the whole submission
        debugPrint('⚠️ Step 5 (about me) failed: $step5 — continuing anyway');
      }
    }

    return null; // success
  }

  static Future<String?> _patch(
    String url,
    Map<String, String> headers,
    Map<String, dynamic> body,
  ) async {
    try {
      debugPrint('📤 PATCH $url');
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      debugPrint('📥 ${response.statusCode} ${response.body.substring(0, response.body.length.clamp(0, 200))}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null; // OK
      }
      return 'Server returned ${response.statusCode}';
    } catch (e) {
      debugPrint('❌ PATCH $url failed: $e');
      return e.toString();
    }
  }
}
