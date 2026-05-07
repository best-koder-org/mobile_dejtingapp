import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../backend_url.dart';
import '../models/match_insight.dart';
import 'api_service.dart';

/// Thrown when the server returns a non-2xx, non-404 response.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class _CacheEntry {
  final MatchInsight insight;
  final DateTime expiresAt;

  _CacheEntry(this.insight, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// API client for `/api/matchmaking/matches/{matchId}/insight`.
///
/// Results are cached in an in-memory LRU cache (max [_cacheMaxSize] entries,
/// default TTL [_defaultCacheTtl]). A cache hit short-circuits the HTTP call.
///
/// - HTTP 404 → returns `null` (insight not yet generated).
/// - Other non-2xx → throws [ApiException].
class MatchInsightService {
  static const int _cacheMaxSize = 50;
  static const Duration _defaultCacheTtl = Duration(minutes: 5);

  final http.Client _httpClient;
  final Future<String?> Function() _tokenProvider;
  final Duration _cacheTtl;

  // LinkedHashMap preserves insertion order for LRU eviction.
  final _cache = LinkedHashMap<int, _CacheEntry>();

  MatchInsightService({
    http.Client? client,
    Future<String?> Function()? tokenProvider,
    Duration cacheTtl = _defaultCacheTtl,
  })  : _httpClient = client ?? http.Client(),
        _tokenProvider =
            tokenProvider ?? (() => AppState().getOrRefreshAuthToken()),
        _cacheTtl = cacheTtl;

  /// Fetches the insight for [matchId].
  ///
  /// Returns `null` when the server responds with 404.
  /// Throws [ApiException] for any other non-2xx status code.
  Future<MatchInsight?> fetchInsight(int matchId) async {
    final cached = _cache[matchId];
    if (cached != null && !cached.isExpired) {
      return cached.insight;
    }
    if (cached != null) {
      _cache.remove(matchId);
    }

    final token = await _tokenProvider();
    if (token == null) {
      debugPrint('MatchInsightService: no auth token, aborting');
      return null;
    }

    final uri = Uri.parse(
      '${ApiUrls.matchmakingService}/api/matchmaking/matches/$matchId/insight',
    );

    final response = await _httpClient.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }

    final insight = MatchInsight.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );

    _putCache(matchId, insight);
    return insight;
  }

  void _putCache(int matchId, MatchInsight insight) {
    if (_cache.length >= _cacheMaxSize && !_cache.containsKey(matchId)) {
      _cache.remove(_cache.keys.first);
    }
    _cache[matchId] = _CacheEntry(insight, DateTime.now().add(_cacheTtl));
  }
}
