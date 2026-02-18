import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../services/messaging_service.dart';
import '../services/matchmaking_realtime_service.dart';

class AppInitializationService {
  static final AppInitializationService _instance =
      AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  final MessagingService _messagingService = MessagingService();
  final MatchmakingRealtimeService _matchmakingRealtimeService =
      MatchmakingRealtimeService();
  bool _isInitialized = false;
  bool _warnedMessagingUnavailable = false;

  Future<void> initializeApp() async {
    if (_isInitialized) return;

    try {
      // Get current user info
      final userId = AppState().userId;
      final authToken = AppState().authToken;

      if (userId != null && authToken != null) {
        // ── Messaging service ──────────────────────────────────────────
        final messagingAvailable = await _isMessagingServiceAvailable();
        if (messagingAvailable) {
          await _messagingService.initialize(userId, authToken);
          if (kDebugMode) {
            print('✅ Messaging service connected (userId=$userId)');
          }
        } else {
          if (!_warnedMessagingUnavailable) {
            if (kDebugMode) {
              print('⚠️ Messaging service unavailable. Skipping initialization.');
            }
            _warnedMessagingUnavailable = true;
          }
        }

        // ── Matchmaking realtime service ───────────────────────────────
        try {
          await _matchmakingRealtimeService.initialize(authToken);
          if (kDebugMode) {
            print('✅ MatchmakingRealtimeService connected');
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ MatchmakingRealtimeService init failed (non-fatal): $e');
          }
        }
      } else {
        if (kDebugMode) {
          print('User not logged in, skipping service initialization');
        }
      }

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) print('Error initializing app: $e');
      // Don't prevent app from starting if services fail
      _isInitialized = true;
    }
  }

  MessagingService get messagingService => _messagingService;
  MatchmakingRealtimeService get matchmakingRealtimeService =>
      _matchmakingRealtimeService;
  bool get isInitialized => _isInitialized;

  void reset() {
    _isInitialized = false;
    _warnedMessagingUnavailable = false;
  }

  Future<bool> _isMessagingServiceAvailable() async {
    final baseUrl = MessagingService.baseUrl;

    if (baseUrl.isEmpty) {
      return false;
    }

    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (e) {
      if (kDebugMode) {
        print('Messaging health check failed: $e');
      }
      return false;
    }
  }
}
