import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../backend_url.dart';

/// Models for the backend billing API.
class EntitlementStatus {
  final String userId;
  final String tier;
  final DateTime? expiresAt;
  final bool isPremium;
  final int sparksBalance;
  final int sparksDailyUsed;
  final int sparksDailyMax;
  final int sparksDailyRemaining;

  EntitlementStatus({
    required this.userId,
    required this.tier,
    this.expiresAt,
    required this.isPremium,
    required this.sparksBalance,
    this.sparksDailyUsed = 0,
    this.sparksDailyMax = 0,
    this.sparksDailyRemaining = 0,
  });

  factory EntitlementStatus.fromJson(Map<String, dynamic> json) {
    // tier can be int (enum value: 1=Premium, 0=Free) or string
    final tierValue = json['tier'];
    final tierStr = tierValue is int
        ? (tierValue == 1 ? 'Premium' : 'Free')
        : tierValue?.toString() ?? 'Free';
    return EntitlementStatus(
        userId: json['userId'] as String? ?? '',
        tier: tierStr,
        expiresAt: json['expiresAt'] != null
            ? DateTime.tryParse(json['expiresAt'] as String)
            : null,
        isPremium: json['isPremium'] as bool? ?? false,
        sparksBalance: json['sparksBalance'] as int? ?? 0,
        sparksDailyUsed: json['sparksDailyUsed'] as int? ?? 0,
        sparksDailyMax: json['sparksDailyMax'] as int? ?? 0,
        sparksDailyRemaining: json['sparksDailyRemaining'] as int? ?? 0,
      );
  }

  /// How many Sparks the user actually has available to spend right now.
  /// Takes into account daily allocation (if remaining) + purchased balance.
  int get availableSparks => sparksDailyRemaining > 0
      ? sparksDailyRemaining
      : sparksBalance;
}

class PremiumPlan {
  final String sku;
  final String name;
  final String description;
  final int durationDays;
  PremiumPlan(this.sku, this.name, this.description, this.durationDays);
}

class SparksBundle {
  final String sku;
  final String name;
  final int sparks;
  final int priceUsdCents;
  SparksBundle(this.sku, this.name, this.sparks, this.priceUsdCents);
}

class PurchaseResult {
  final String message;
  final String? newTier;
  final int? sparksAwarded;
  PurchaseResult(this.message, this.newTier, this.sparksAwarded);
}

/// Result of a Spark spend action.
class SpendSparkResult {
  final bool success;
  final int newBalance;
  final int dailyRemaining;
  final String? error;
  SpendSparkResult(this.success, this.newBalance, this.dailyRemaining, this.error);
}

/// Catalog result from the backend.
class CatalogResult {
  final List<PremiumPlan> plans;
  final List<SparksBundle> bundles;
  CatalogResult(this.plans, this.bundles);
}

/// Flutter client for UserService BillingController (P1).
class BillingService {
  /// Fetch entitlement + sparks balance for the current user.
  /// Fetch entitlement + sparks balance for the current user.
  static Future<EntitlementStatus> getStatus() async {
    await AppState().initialize();
    final token = await AppState().getOrRefreshAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${ApiUrls.gateway}/api/billing/status'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Failed to load billing status');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return EntitlementStatus.fromJson(body);
  }

  /// Fetch the premium catalog (public endpoint).
  static Future<CatalogResult> getCatalog() async {
    final response = await http.get(
      Uri.parse('${ApiUrls.gateway}/api/billing/catalog'),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception('Failed to load catalog (${response.statusCode})');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return CatalogResult(
      (body['plans'] as List<dynamic>? ?? [])
          .map((p) => PremiumPlan(
                p['sku'] as String? ?? '',
                p['name'] as String? ?? '',
                p['description'] as String? ?? '',
                p['durationDays'] as int? ?? 0,
              ))
          .toList(),
      (body['bundles'] as List<dynamic>? ?? [])
          .map((b) => SparksBundle(
                b['sku'] as String? ?? '',
                b['name'] as String? ?? '',
                b['sparks'] as int? ?? 0,
                b['priceUsdCents'] as int? ?? 0,
              ))
          .toList(),
    );
  }

  /// Sandbox purchase — immediately grants the item. No real payment.
  static Future<PurchaseResult> purchase(String sku) async {
    await AppState().initialize();
    final token = await AppState().getOrRefreshAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${ApiUrls.gateway}/api/billing/purchase'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'sku': sku}),
    );
    if (response.statusCode != 200) throw Exception('Purchase failed');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? body;

    // tier can be int (enum value: 1=Premium, 0=Free) or string
    final tierValue = data['tier'];
    final tierStr = tierValue is int
        ? (tierValue == 1 ? 'Premium' : 'Free')
        : tierValue?.toString();

    // newBalance is present for spark purchases; sparksAwarded for bundles
    final balance = data['newBalance'] as int? ?? data['sparksAwarded'] as int?;

    return PurchaseResult(
      body['message'] as String? ?? 'Purchase complete',
      tierStr,
      balance,
    );
  }

  /// Check if the current user is premium (simple boolean).
  static Future<bool> isPremium() async {
    try {
      final status = await getStatus();
      return status.isPremium;
    } catch (_) {
      return false;
    }
  }

  /// Spend one Spark for an action (ping, rewind, super-like, boost).
  /// Returns a SpendSparkResult with the new balance.
  static Future<SpendSparkResult> spendSpark(String action) async {
    await AppState().initialize();
    final token = await AppState().getOrRefreshAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${ApiUrls.gateway}/api/billing/sparks/spend'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'action': action}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return SpendSparkResult(
        data['success'] as bool? ?? false,
        data['newBalance'] as int? ?? 0,
        data['dailyRemaining'] as int? ?? 0,
        null,
      );
    }

    return SpendSparkResult(
      false, 0, 0,
      (body['message'] as String?) ?? 'Failed to spend Spark',
    );
  }
}

/// Result of sending a Spark to another user.
class SendSparkResult {
  final bool success;
  final int newBalance;
  final int dailyRemaining;
  final String? error;
  final int? sparkRecordId;
  SendSparkResult(this.success, this.newBalance, this.dailyRemaining, this.error, this.sparkRecordId);
}

/// A Spark received from another user (for Sparks tab).
class SparkReceived {
  final int id;
  final String senderUserId;
  final String recipientUserId;
  final String? message;
  final bool isRead;
  final DateTime createdAt;
  final String? senderDisplayName;
  final String? senderPhotoUrl;

  SparkReceived({
    required this.id,
    required this.senderUserId,
    required this.recipientUserId,
    this.message,
    required this.isRead,
    required this.createdAt,
    this.senderDisplayName,
    this.senderPhotoUrl,
  });

  factory SparkReceived.fromJson(Map<String, dynamic> json) => SparkReceived(
    id: json['id'] as int? ?? 0,
    senderUserId: json['senderUserId'] as String? ?? '',
    recipientUserId: json['recipientUserId'] as String? ?? '',
    message: json['message'] as String?,
    isRead: json['isRead'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    senderDisplayName: json['senderDisplayName'] as String?,
    senderPhotoUrl: json['senderPhotoUrl'] as String?,
  );
}

/// Result of fetching received/sent sparks.
class SparksListResult {
  final List<SparkReceived> sparks;
  final int totalCount;
  SparksListResult(this.sparks, this.totalCount);
}

extension BillingServiceSparks on BillingService {
  /// Send a Spark to another user with an optional message.
  /// Calls POST /api/billing/sparks/send
  static Future<SendSparkResult> sendSpark(String recipientUserId, {String? message}) async {
    await AppState().initialize();
    final token = await AppState().getOrRefreshAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${ApiUrls.gateway}/api/billing/sparks/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'recipientUserId': recipientUserId,
        if (message != null && message.isNotEmpty) 'message': message,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return SendSparkResult(
        data['success'] as bool? ?? false,
        data['newBalance'] as int? ?? 0,
        data['dailyRemaining'] as int? ?? 0,
        null,
        data['sparkRecordId'] as int?,
      );
    }

    return SendSparkResult(
      false, 0, 0,
      (body['message'] as String?) ?? 'Failed to send Spark',
      null,
    );
  }

  /// Get Sparks received by the current user.
  static Future<SparksListResult> getReceivedSparks({int page = 1, int pageSize = 50}) async {
    await AppState().initialize();
    final token = await AppState().getOrRefreshAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${ApiUrls.gateway}/api/billing/sparks/received?page=$page&pageSize=$pageSize'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) throw Exception('Failed to load received sparks');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? body;
    final sparks = (data['sparks'] as List<dynamic>? ?? [])
        .map((s) => SparkReceived.fromJson(s as Map<String, dynamic>))
        .toList();
    return SparksListResult(sparks, data['totalCount'] as int? ?? sparks.length);
  }
}
