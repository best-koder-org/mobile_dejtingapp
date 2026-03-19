import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'swipe_service.dart';
import '../models.dart';

/// A pending swipe action waiting to be sent when connectivity is restored.
class PendingSwipe {
  final String id;
  final String targetUserId;
  final bool isLike;
  final String idempotencyKey;
  final DateTime createdAt;
  int retryCount;

  PendingSwipe({
    required this.id,
    required this.targetUserId,
    required this.isLike,
    required this.idempotencyKey,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetUserId': targetUserId,
        'isLike': isLike,
        'idempotencyKey': idempotencyKey,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory PendingSwipe.fromJson(Map<String, dynamic> json) => PendingSwipe(
        id: json['id'] ?? '',
        targetUserId: json['targetUserId'] ?? '',
        isLike: json['isLike'] ?? false,
        idempotencyKey: json['idempotencyKey'] ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        retryCount: json['retryCount'] ?? 0,
      );
}

/// Result of a swipe attempt from the cache service.
class SwipeCacheResult {
  final bool sentImmediately;
  final bool queued;
  final bool isMatch;
  final String? matchId;
  final String? error;

  SwipeCacheResult({
    this.sentImmediately = false,
    this.queued = false,
    this.isMatch = false,
    this.matchId,
    this.error,
  });
}

/// T037: Offline cache strategy for swipe queue + candidate caching.
///
/// Responsibilities:
/// 1. Cache loaded candidates to SharedPreferences for offline browsing
/// 2. Queue swipes that fail due to network errors
/// 3. Drain the pending swipe queue when connectivity is restored
/// 4. Deduplicate swipes using idempotency keys
/// 5. Expire stale cache entries (candidates older than 1 hour)
class SwipeCacheService {
  static const _uuid = Uuid();

  // SharedPreferences keys
  static const _pendingSwipesKey = 'swipe_cache_pending_swipes';
  static const _cachedCandidatesKey = 'swipe_cache_candidates';
  static const _candidatesCachedAtKey = 'swipe_cache_candidates_ts';
  static const _swipedUserIdsKey = 'swipe_cache_swiped_ids';
  static const _lastDrainAtKey = 'swipe_cache_last_drain';

  // Limits
  static const _maxPendingSwipes = 100;
  static const _maxCachedCandidates = 50;
  static const _candidateCacheTtlMinutes = 60;
  static const _maxRetries = 5;
  static const _drainBatchSize = 10;

  // Singleton
  static final SwipeCacheService _instance = SwipeCacheService._internal();
  factory SwipeCacheService() => _instance;
  SwipeCacheService._internal();

  // In-memory state (loaded from SharedPreferences on init)
  List<PendingSwipe> _pendingSwipes = [];
  List<MatchCandidate> _cachedCandidates = [];
  Set<String> _swipedUserIds = {};
  DateTime? _candidatesCachedAt;
  bool _initialized = false;
  bool _isDraining = false;
  Timer? _drainTimer;

  // Callbacks
  VoidCallback? onPendingSwipesChanged;
  void Function(String targetUserId, bool isMatch, String? matchId)?
      onSwipeDrained;

  /// Initialize — load persisted state from SharedPreferences.
  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();

    // Load pending swipes
    final swipesJson = prefs.getString(_pendingSwipesKey);
    if (swipesJson != null) {
      try {
        final list = json.decode(swipesJson) as List;
        _pendingSwipes =
            list.map((e) => PendingSwipe.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Failed to load pending swipes: $e');
        _pendingSwipes = [];
      }
    }

    // Load cached candidates
    final candidatesJson = prefs.getString(_cachedCandidatesKey);
    if (candidatesJson != null) {
      try {
        final list = json.decode(candidatesJson) as List;
        _cachedCandidates =
            list.map((e) => MatchCandidate.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Failed to load cached candidates: $e');
        _cachedCandidates = [];
      }
    }

    // Load cache timestamp
    final tsStr = prefs.getString(_candidatesCachedAtKey);
    _candidatesCachedAt = tsStr != null ? DateTime.tryParse(tsStr) : null;

    // Load swiped user IDs (for dedup)
    final swipedJson = prefs.getString(_swipedUserIdsKey);
    if (swipedJson != null) {
      try {
        _swipedUserIds =
            (json.decode(swipedJson) as List).map((e) => e.toString()).toSet();
      } catch (_) {
        _swipedUserIds = {};
      }
    }

    _initialized = true;

    // Start periodic drain timer (every 30 seconds)
    _startDrainTimer();

    if (kDebugMode) {
      debugPrint('SwipeCacheService initialized: '
          '${_pendingSwipes.length} pending swipes, '
          '${_cachedCandidates.length} cached candidates, '
          '${_swipedUserIds.length} swiped IDs');
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  // Candidate Cache
  // ──────────────────────────────────────────────────────────────────────

  /// Cache a batch of candidates for offline browsing.
  Future<void> cacheCandidates(List<MatchCandidate> candidates) async {
    if (candidates.isEmpty) return;

    // Filter out already-swiped candidates
    final fresh = candidates
        .where((c) => !_swipedUserIds.contains(c.userId))
        .toList();

    // Merge with existing cache (avoid duplicates by userId)
    final existingIds = _cachedCandidates.map((c) => c.userId).toSet();
    for (final c in fresh) {
      if (!existingIds.contains(c.userId)) {
        _cachedCandidates.add(c);
        existingIds.add(c.userId);
      }
    }

    // Trim to max size (keep newest)
    if (_cachedCandidates.length > _maxCachedCandidates) {
      _cachedCandidates = _cachedCandidates
          .sublist(_cachedCandidates.length - _maxCachedCandidates);
    }

    _candidatesCachedAt = DateTime.now();
    await _persistCandidates();

    if (kDebugMode) {
      debugPrint('Cached ${fresh.length} candidates '
          '(total: ${_cachedCandidates.length})');
    }
  }

  /// Get cached candidates for offline swiping.
  ///
  /// Returns empty list if cache is expired or empty.
  List<MatchCandidate> getCachedCandidates() {
    if (!_initialized || _cachedCandidates.isEmpty) return [];

    // Check TTL
    if (_candidatesCachedAt != null) {
      final age = DateTime.now().difference(_candidatesCachedAt!);
      if (age.inMinutes > _candidateCacheTtlMinutes) {
        if (kDebugMode) debugPrint('Candidate cache expired (${age.inMinutes}min)');
        return [];
      }
    }

    // Filter out already-swiped candidates
    return _cachedCandidates
        .where((c) => !_swipedUserIds.contains(c.userId))
        .toList();
  }

  /// Whether we have usable cached candidates.
  bool get hasCachedCandidates => getCachedCandidates().isNotEmpty;

  /// Clear the candidate cache.
  Future<void> clearCandidateCache() async {
    _cachedCandidates = [];
    _candidatesCachedAt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedCandidatesKey);
    await prefs.remove(_candidatesCachedAtKey);
  }

  // ──────────────────────────────────────────────────────────────────────
  // Swipe Queue
  // ──────────────────────────────────────────────────────────────────────

  /// Record a swipe — tries to send immediately, queues on failure.
  ///
  /// Returns a [SwipeCacheResult] indicating whether the swipe was sent
  /// immediately or queued for later delivery.
  Future<SwipeCacheResult> recordSwipe({
    required String targetUserId,
    required bool isLike,
  }) async {
    final idempotencyKey = _uuid.v4();

    // Track as swiped immediately (prevents showing this card again)
    _swipedUserIds.add(targetUserId);
    await _persistSwipedIds();

    // Try to send immediately
    try {
      final result = await SwipeService.swipe(
        targetUserId: targetUserId,
        isLike: isLike,
        idempotencyKey: idempotencyKey,
      );

      if (result != null) {
        final isMatch = result['isMatch'] == true;
        final matchId = result['matchId']?.toString();
        return SwipeCacheResult(
          sentImmediately: true,
          isMatch: isMatch,
          matchId: matchId,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Swipe send failed, queueing: $e');
    }

    // Failed to send — queue for later
    return await _queueSwipe(
      targetUserId: targetUserId,
      isLike: isLike,
      idempotencyKey: idempotencyKey,
    );
  }

  /// Queue a swipe for later delivery.
  Future<SwipeCacheResult> _queueSwipe({
    required String targetUserId,
    required bool isLike,
    required String idempotencyKey,
  }) async {
    // Check for duplicate (same target user)
    final existing = _pendingSwipes.any((s) => s.targetUserId == targetUserId);
    if (existing) {
      if (kDebugMode) debugPrint('Swipe already queued for $targetUserId');
      return SwipeCacheResult(queued: true);
    }

    // Enforce queue size limit
    if (_pendingSwipes.length >= _maxPendingSwipes) {
      // Remove oldest entries to make room
      _pendingSwipes.removeAt(0);
    }

    final pending = PendingSwipe(
      id: _uuid.v4(),
      targetUserId: targetUserId,
      isLike: isLike,
      idempotencyKey: idempotencyKey,
      createdAt: DateTime.now(),
    );

    _pendingSwipes.add(pending);
    await _persistPendingSwipes();
    onPendingSwipesChanged?.call();

    if (kDebugMode) {
      debugPrint('Swipe queued for $targetUserId '
          '(${isLike ? "LIKE" : "PASS"}) — '
          '${_pendingSwipes.length} pending');
    }

    return SwipeCacheResult(queued: true);
  }

  /// Number of pending swipes in the queue.
  int get pendingSwipeCount => _pendingSwipes.length;

  /// Whether there are pending swipes to drain.
  bool get hasPendingSwipes => _pendingSwipes.isNotEmpty;

  // ──────────────────────────────────────────────────────────────────────
  // Queue Drain
  // ──────────────────────────────────────────────────────────────────────

  /// Attempt to drain the pending swipe queue.
  ///
  /// Called periodically by the timer and on connectivity change.
  /// Uses batch processing with configurable batch size.
  Future<void> drainQueue() async {
    if (_isDraining || _pendingSwipes.isEmpty) return;
    _isDraining = true;

    if (kDebugMode) {
      debugPrint('Draining swipe queue (${_pendingSwipes.length} pending)...');
    }

    final toRemove = <String>[];
    final batch = _pendingSwipes.take(_drainBatchSize).toList();

    for (final swipe in batch) {
      // Skip swipes that have exceeded max retries
      if (swipe.retryCount >= _maxRetries) {
        if (kDebugMode) {
          debugPrint('Dropping swipe ${swipe.id} after $_maxRetries retries');
        }
        toRemove.add(swipe.id);
        continue;
      }

      try {
        final result = await SwipeService.swipe(
          targetUserId: swipe.targetUserId,
          isLike: swipe.isLike,
          idempotencyKey: swipe.idempotencyKey,
        );

        if (result != null) {
          // Success — remove from queue
          toRemove.add(swipe.id);
          final isMatch = result['isMatch'] == true;
          final matchId = result['matchId']?.toString();

          if (kDebugMode) {
            debugPrint('Drained swipe for ${swipe.targetUserId} ${isMatch ? "(MATCH!)" : ""}');
          }

          // Notify about result (especially matches discovered while offline)
          onSwipeDrained?.call(swipe.targetUserId, isMatch, matchId);
        } else {
          // SwipeService returned null (all retries failed)
          swipe.retryCount++;
          if (kDebugMode) {
            debugPrint('Drain attempt failed for ${swipe.targetUserId} '
                '(retry ${swipe.retryCount}/$_maxRetries)');
          }
          // Stop draining — server might be down
          break;
        }
      } catch (e) {
        swipe.retryCount++;
        if (kDebugMode) {
          debugPrint('Drain error for ${swipe.targetUserId}: $e');
        }
        // Stop draining on first failure — don't hammer a down server
        break;
      }
    }

    // Remove successfully sent swipes
    _pendingSwipes.removeWhere((s) => toRemove.contains(s.id));
    await _persistPendingSwipes();
    onPendingSwipesChanged?.call();

    _isDraining = false;

    // Update last drain timestamp
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDrainAtKey, DateTime.now().toIso8601String());

    if (kDebugMode && toRemove.isNotEmpty) {
      debugPrint('Drained ${toRemove.length} swipes, '
          '${_pendingSwipes.length} remaining');
    }
  }

  /// Start the periodic drain timer.
  void _startDrainTimer() {
    _drainTimer?.cancel();
    _drainTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      drainQueue();
    });
  }

  /// Call when network connectivity is restored (e.g. from a connectivity
  /// change listener). Triggers an immediate drain attempt.
  Future<void> onConnectivityRestored() async {
    if (kDebugMode) debugPrint('Connectivity restored — draining swipe queue');
    await drainQueue();
  }

  // ──────────────────────────────────────────────────────────────────────
  // Swiped-user tracking (prevents re-showing cards)
  // ──────────────────────────────────────────────────────────────────────

  /// Whether this user has already been swiped (online or offline).
  bool isAlreadySwiped(String userId) => _swipedUserIds.contains(userId);

  /// Clear swiped-user history (e.g. on logout).
  Future<void> clearSwipedHistory() async {
    _swipedUserIds.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_swipedUserIdsKey);
  }

  // ──────────────────────────────────────────────────────────────────────
  // Persistence helpers
  // ──────────────────────────────────────────────────────────────────────

  Future<void> _persistPendingSwipes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _pendingSwipes.map((s) => s.toJson()).toList();
    await prefs.setString(_pendingSwipesKey, json.encode(jsonList));
  }

  Future<void> _persistCandidates() async {
    final prefs = await SharedPreferences.getInstance();
    // Serialize candidates using toJson-compatible map
    final jsonList = _cachedCandidates.map((c) => _candidateToJson(c)).toList();
    await prefs.setString(_cachedCandidatesKey, json.encode(jsonList));
    if (_candidatesCachedAt != null) {
      await prefs.setString(
          _candidatesCachedAtKey, _candidatesCachedAt!.toIso8601String());
    }
  }

  Future<void> _persistSwipedIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _swipedUserIdsKey, json.encode(_swipedUserIds.toList()));
  }

  /// Convert a MatchCandidate to a JSON map for persistence.
  Map<String, dynamic> _candidateToJson(MatchCandidate c) => {
        'userId': c.userId,
        'displayName': c.displayName,
        'photoUrl': c.photoUrl,
        'photoUrls': c.photoUrls,
        'age': c.age,
        'bio': c.bio,
        'city': c.city,
        'distanceKm': c.distanceKm,
        'compatibility': c.compatibility,
        'interestsOverlap': c.interestsOverlap,
        'occupation': c.occupation,
      };

  // ──────────────────────────────────────────────────────────────────────
  // Cleanup
  // ──────────────────────────────────────────────────────────────────────

  /// Clear all cached data (e.g. on logout).
  Future<void> clearAll() async {
    _pendingSwipes = [];
    _cachedCandidates = [];
    _swipedUserIds = {};
    _candidatesCachedAt = null;
    _drainTimer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingSwipesKey);
    await prefs.remove(_cachedCandidatesKey);
    await prefs.remove(_candidatesCachedAtKey);
    await prefs.remove(_swipedUserIdsKey);
    await prefs.remove(_lastDrainAtKey);
  }

  /// Dispose resources.
  void dispose() {
    _drainTimer?.cancel();
  }
}
