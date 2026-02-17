import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../backend_url.dart';
import '../models/onboarding_data.dart';
import 'api_service.dart';

/// Submits collected onboarding wizard data to UserService.
///
/// Calls the 3 wizard PATCH endpoints in sequence:
///   PATCH /api/wizard/step/1  → BasicInfo  (name, dob, gender)
///   PATCH /api/wizard/step/2  → Preferences (ages, distance, bio)
///   PATCH /api/wizard/step/3  → Photos     (photo URLs)
///
/// Returns `true` if all calls succeed.
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

    // Step 1: Basic Info
    final step1 = await _patch(
      '$base/api/wizard/step/1',
      headers,
      data.toBasicInfoPayload(),
    );
    if (step1 != null) return 'Step 1 (profile): $step1';

    // Step 2: Preferences
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
