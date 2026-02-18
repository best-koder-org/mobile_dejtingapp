import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../backend_url.dart';
import 'api_service.dart';

/// Real-time match notification via SignalR.
///
/// Connects to MatchmakingHub at `/hubs/matchmaking` through the YARP gateway.
/// Emits [MatchNotification] events on [matchStream] when the backend fires
/// `MatchCreated`.
///
/// T036: Real-time match creation notifications (Flutter side).
class MatchmakingRealtimeService {
  // ── Singleton ──────────────────────────────────────────────────────────
  static final MatchmakingRealtimeService _instance =
      MatchmakingRealtimeService._internal();
  factory MatchmakingRealtimeService() => _instance;
  MatchmakingRealtimeService._internal();

  // ── Hub URL ────────────────────────────────────────────────────────────
  static String get hubUrl => '${ApiUrls.gateway}/hubs/matchmaking';

  // ── Connection ─────────────────────────────────────────────────────────
  HubConnection? _hubConnection;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // ── Streams ────────────────────────────────────────────────────────────
  final StreamController<MatchNotification> _matchController =
      StreamController<MatchNotification>.broadcast();
  Stream<MatchNotification> get matchStream => _matchController.stream;

  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  // ── Reconnection ──────────────────────────────────────────────────────
  static const int _maxReconnectAttempts = 5;
  static const Duration _baseDelay = Duration(seconds: 2);
  static const Duration _maxDelay = Duration(seconds: 60);
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;

  // ── Auth ───────────────────────────────────────────────────────────────
  // ignore: unused_field
  String? _authToken;

  // ═══════════════════════════════════════════════════════════════════════
  // Initialization
  // ═══════════════════════════════════════════════════════════════════════

  /// Start the service. Call once after login or app init.
  Future<void> initialize(String authToken) async {
    _authToken = authToken;
    await _connectToHub();
    if (kDebugMode) print('✅ MatchmakingRealtimeService initialized');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SignalR Connection
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _connectToHub() async {
    if (_isConnected) return;

    _setStatus('Connecting…');

    try {
      _hubConnection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async {
                // Always get a fresh/valid token
                final token = await AppState().getOrRefreshAuthToken();
                _authToken = token;
                return token ?? '';
              },
              transport: HttpTransportType.WebSockets,
              skipNegotiation: false,
              logMessageContent: kDebugMode,
            ),
          )
          .build();

      // ── Server → Client events ──────────────────────────────────────
      _hubConnection!.on('MatchCreated', _onMatchCreated);
      _hubConnection!.on('Subscribed', _onSubscribed);
      _hubConnection!.on('Error', _onHubError);

      // ── Connection lifecycle ────────────────────────────────────────
      _hubConnection!.onclose(({Exception? error}) {
        if (kDebugMode) print('MatchmakingHub closed: $error');
        _isConnected = false;
        _setStatus('Disconnected');
        _scheduleReconnect();
      });

      _hubConnection!.onreconnecting(({Exception? error}) {
        if (kDebugMode) print('MatchmakingHub reconnecting: $error');
        _setStatus('Reconnecting…');
      });

      _hubConnection!.onreconnected(({String? connectionId}) {
        if (kDebugMode) print('MatchmakingHub reconnected: $connectionId');
        _onConnected();
      });

      await _hubConnection!.start();
      _onConnected();
    } catch (e) {
      if (kDebugMode) print('❌ MatchmakingHub connect failed: $e');
      _isConnected = false;
      _setStatus('Connection failed');
      _scheduleReconnect();
    }
  }

  void _onConnected() {
    _isConnected = true;
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    _setStatus('Connected');

    // Tell the hub we're ready
    _hubConnection?.invoke('Subscribe');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Reconnection (exponential backoff with jitter)
  // ═══════════════════════════════════════════════════════════════════════

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    if (_reconnectAttempt >= _maxReconnectAttempts) {
      if (kDebugMode) {
        print('⚠️ MatchmakingHub max reconnect attempts reached');
      }
      // Keep trying at long intervals
      _reconnectTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        if (!_isConnected) {
          _reconnectAttempt = 0;
          _connectToHub();
        }
      });
      return;
    }

    final delay = Duration(
      milliseconds: min(
        _maxDelay.inMilliseconds,
        _baseDelay.inMilliseconds * pow(2, _reconnectAttempt).toInt() +
            Random().nextInt(1000),
      ),
    );

    _reconnectAttempt++;
    if (kDebugMode) {
      print('🔄 MatchmakingHub reconnect #$_reconnectAttempt in ${delay.inSeconds}s');
    }

    _reconnectTimer = Timer(delay, () {
      if (!_isConnected) _connectToHub();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Event Handlers
  // ═══════════════════════════════════════════════════════════════════════

  void _onMatchCreated(List<Object?>? parameters) {
    if (parameters == null || parameters.isEmpty) return;
    try {
      final data = parameters[0] as Map<String, dynamic>;
      final notification = MatchNotification.fromJson(data);
      _matchController.add(notification);
      if (kDebugMode) {
        print('🎉 MatchCreated: matchId=${notification.matchId} '
            'with=${notification.matchedWithUserId}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ _onMatchCreated parse error: $e');
    }
  }

  void _onSubscribed(List<Object?>? parameters) {
    if (kDebugMode) {
      print('✅ Subscribed to match notifications');
    }
  }

  void _onHubError(List<Object?>? parameters) {
    final error = parameters?.firstOrNull?.toString() ?? 'Unknown';
    if (kDebugMode) print('❌ MatchmakingHub error: $error');
    _setStatus('Error: $error');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════════

  void _setStatus(String status) {
    _statusController.add(status);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Cleanup
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    try {
      await _hubConnection?.stop();
    } catch (_) {}
    _isConnected = false;
    _setStatus('Disconnected');
    if (kDebugMode) print('👋 MatchmakingRealtimeService disconnected');
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _matchController.close();
    _statusController.close();
    _hubConnection?.stop();
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Model
// ═════════════════════════════════════════════════════════════════════════════

/// Payload for a `MatchCreated` event from the MatchmakingHub.
class MatchNotification {
  final String type;
  final int matchId;
  final String userId;
  final String matchedWithUserId;
  final String message;
  final DateTime timestamp;

  MatchNotification({
    required this.type,
    required this.matchId,
    required this.userId,
    required this.matchedWithUserId,
    required this.message,
    required this.timestamp,
  });

  factory MatchNotification.fromJson(Map<String, dynamic> json) {
    return MatchNotification(
      type: json['Type'] as String? ?? json['type'] as String? ?? 'Match',
      matchId: _parseInt(json['MatchId'] ?? json['matchId']),
      userId: (json['UserId'] ?? json['userId'] ?? '').toString(),
      matchedWithUserId:
          (json['MatchedWithUserId'] ?? json['matchedWithUserId'] ?? '')
              .toString(),
      message: json['Message'] as String? ??
          json['message'] as String? ??
          'You have a new match! 🎉',
      timestamp: DateTime.tryParse(
              (json['Timestamp'] ?? json['timestamp'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
