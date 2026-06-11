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

  factory EntitlementStatus.fromJson(Map<String, dynamic> json) =>
      EntitlementStatus(
        userId: json['userId'] as String? ?? '',
        tier: json['tier'] as String? ?? 'Free',
        expiresAt: json['expiresAt'] != null
            ? DateTime.tryParse(json['expiresAt'] as String)
            : null,
        isPremium: json['isPremium'] as bool? ?? false,
        sparksBalance: json['sparksBalance'] as int? ?? 0,
        sparksDailyUsed: json['sparksDailyUsed'] as int? ?? 0,
        sparksDailyMax: json['sparksDailyMax'] as int? ?? 0,
        sparksDailyRemaining: json['sparksDailyRemaining'] as int? ?? 0,
      );

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
    return PurchaseResult(
      body['message'] as String? ?? 'Purchase complete',
      data['tier'] as String?,
      data['newBalance'] as int?,
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
