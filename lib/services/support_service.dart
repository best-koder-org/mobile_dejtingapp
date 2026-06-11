import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../backend_url.dart';

/// Categories accepted by UserService SupportController (must match enum order/name).
enum SupportCategory { bug, feature, account, safety, other }

extension SupportCategoryX on SupportCategory {
  /// Wire value expected by the backend enum (stored as string).
  String get wireName {
    switch (this) {
      case SupportCategory.bug:
        return 'Bug';
      case SupportCategory.feature:
        return 'Feature';
      case SupportCategory.account:
        return 'Account';
      case SupportCategory.safety:
        return 'Safety';
      case SupportCategory.other:
        return 'Other';
    }
  }

  String get label {
    switch (this) {
      case SupportCategory.bug:
        return 'Report a bug';
      case SupportCategory.feature:
        return 'Suggest a feature';
      case SupportCategory.account:
        return 'Account help';
      case SupportCategory.safety:
        return 'Safety concern';
      case SupportCategory.other:
        return 'Something else';
    }
  }
}

/// Client for the support/feedback endpoints (UserService SupportController, T091).
class SupportService {
  /// Submit a support ticket. Returns the created ticket id on success.
  static Future<String> submitFeedback({
    required SupportCategory category,
    required String subject,
    required String description,
    String? contactEmail,
  }) async {
    await AppState().initialize();
    final token = await AppState().getOrRefreshAuthToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.post(
      Uri.parse('${ApiUrls.gateway}/api/support/feedback'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'category': category.wireName,
        'subject': subject,
        'description': description,
        if (contactEmail != null && contactEmail.isNotEmpty)
          'contactEmail': contactEmail,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      return (data?['ticketId'] as String?) ?? '';
    }

    String message = 'Failed to submit feedback';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = (body['message'] as String?) ?? message;
    } catch (_) {}
    throw Exception(message);
  }
}
