import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../backend_url.dart';
import '../models.dart';

/// Connection state for the messaging service.
enum ConnectionState { disconnected, connecting, connected, reconnecting }

/// A pending message waiting to be sent when connectivity is restored.
class PendingMessage {
  final String localId;
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  int retryCount;

  PendingMessage({
    required this.localId,
    required this.receiverId,
    required this.content,
    this.type = MessageType.text,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'receiverId': receiverId,
        'content': content,
        'type': type.index,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory PendingMessage.fromJson(Map<String, dynamic> json) => PendingMessage(
        localId: json['localId'] ?? '',
        receiverId: json['receiverId'] ?? '',
        content: json['content'] ?? '',
        type: MessageType.values[json['type'] ?? 0],
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        retryCount: json['retryCount'] ?? 0,
      );
}

/// Unified messaging service: SignalR primary → REST fallback → offline queue.
///
/// Implements T044: offline queue + reconnection handling for Flutter messaging.
class MessagingService {
  static String get baseUrl => ApiUrls.messagingService;
  static String get hubUrl => '${ApiUrls.messagingService}/messagingHub';

  // --- Singleton ---
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  // --- SignalR ---
  HubConnection? _hubConnection;
  ConnectionState _connectionState = ConnectionState.disconnected;

  // --- Streams ---
  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();
  final StreamController<String> _connectionStatusController =
      StreamController<String>.broadcast();

  Stream<Message> get messageStream => _messageController.stream;
  Stream<String> get connectionStatusStream =>
      _connectionStatusController.stream;

  // --- Typing indicator ---
  final StreamController<Map<String, dynamic>> _typingController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;

  // --- Read receipt notifications ---
  final StreamController<String> _readReceiptController =
      StreamController<String>.broadcast();
  Stream<String> get readReceiptStream => _readReceiptController.stream;
  ConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == ConnectionState.connected;

  // --- In-memory cache ---
  final Map<String, List<Message>> _conversationCache = {};

  // --- Credentials ---
  String? _currentUserId;
  String? _authToken;

  // --- Reconnection ---
  static const int _maxReconnectAttempts = 5;
  static const Duration _baseReconnectDelay = Duration(seconds: 2);
  static const Duration _maxReconnectDelay = Duration(seconds: 60);
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;

  // --- Offline queue ---
  static const String _pendingQueueKey = 'messaging_pending_queue';
  static const int _maxRetries = 10;
  List<PendingMessage> _pendingQueue = [];
  Timer? _flushTimer;
  bool _isFlushing = false;

  // --- REST polling fallback ---
  Timer? _pollingTimer;
  bool _usePollingFallback = false;
  bool _hasConnectionIssue = false;

  // =========================================================================
  // Initialization
  // =========================================================================

  /// Initialize the service with user credentials. Call once after login.
  Future<void> initialize(String userId, String authToken) async {
    _currentUserId = userId;
    _authToken = authToken;

    // Restore pending queue from disk
    await _loadPendingQueue();

    // Try SignalR first
    await _connectToHub();

    // Start periodic queue flush (every 10s)
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _flushPendingQueue();
    });

    if (kDebugMode) {
      print('✅ MessagingService initialized (userId=$userId)');
    }
  }

  // =========================================================================
  // SignalR Connection
  // =========================================================================

  Future<void> _connectToHub() async {
    if (_connectionState == ConnectionState.connecting) return;

    _setConnectionState(ConnectionState.connecting);

    try {
      _hubConnection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => _authToken ?? '',
              transport: HttpTransportType.WebSockets,
              skipNegotiation: false,
              logMessageContent: kDebugMode,
            ),
          )
          .build();

      // --- Server → Client event handlers ---
      _hubConnection!.on('ReceiveMessage', _onReceiveMessage);
      _hubConnection!.on('MessageReceived', _onReceiveMessage); // MMP spec name
      _hubConnection!.on('MessageSent', _onMessageSent);
      _hubConnection!.on('MessageRead', _onMessageRead);
      _hubConnection!.on('TypingChanged', _onTypingChanged);
      _hubConnection!.on('Error', _onHubError);

      // --- Connection lifecycle ---
      _hubConnection!.onclose(({Exception? error}) {
        if (kDebugMode) print('SignalR closed: $error');
        _setConnectionState(ConnectionState.disconnected);
        _scheduleReconnect();
      });

      _hubConnection!.onreconnecting(({Exception? error}) {
        if (kDebugMode) print('SignalR reconnecting: $error');
        _setConnectionState(ConnectionState.reconnecting);
      });

      _hubConnection!.onreconnected(({String? connectionId}) {
        if (kDebugMode) print('SignalR reconnected: $connectionId');
        _onConnected();
      });

      await _hubConnection!.start();
      _onConnected();
    } catch (e) {
      if (kDebugMode) print('❌ SignalR connect failed: $e');
      _setConnectionState(ConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  /// Called when SignalR successfully connects or reconnects.
  void _onConnected() {
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    _usePollingFallback = false;
    _pollingTimer?.cancel();
    _setConnectionState(ConnectionState.connected);

    // Flush any queued messages now that we're online
    _flushPendingQueue();
  }

  // =========================================================================
  // Exponential-Backoff Reconnection
  // =========================================================================

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    if (_reconnectAttempt >= _maxReconnectAttempts) {
      if (kDebugMode) {
        print('⚠️ Max reconnect attempts reached — falling back to REST polling');
      }
      _startPollingFallback();
      return;
    }

    // Exponential backoff with jitter: base * 2^attempt + random(0..1s)
    final delay = Duration(
      milliseconds: min(
        _maxReconnectDelay.inMilliseconds,
        _baseReconnectDelay.inMilliseconds * pow(2, _reconnectAttempt).toInt() +
            Random().nextInt(1000),
      ),
    );

    _reconnectAttempt++;
    if (kDebugMode) {
      print('🔄 Reconnect attempt $_reconnectAttempt in ${delay.inSeconds}s');
    }

    _setConnectionState(ConnectionState.reconnecting);
    _reconnectTimer = Timer(delay, () {
      if (_connectionState != ConnectionState.connected) {
        _connectToHub();
      }
    });
  }

  // =========================================================================
  // REST Polling Fallback
  // =========================================================================

  void _startPollingFallback() {
    if (_usePollingFallback) return;
    _usePollingFallback = true;
    _setConnectionState(ConnectionState.disconnected);
    _connectionStatusController.add('Using REST (offline mode)');

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollForNewMessages();
    });

    // Periodically retry SignalR (every 60s)
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_connectionState != ConnectionState.connected) {
        _reconnectAttempt = 0;
        _connectToHub();
      }
    });

    if (kDebugMode) {
      print('📡 REST polling fallback active');
    }
  }

  Future<void> _pollForNewMessages() async {
    // Refresh all cached conversations via REST
    for (final conversationId in _conversationCache.keys.toList()) {
      final parts = conversationId.split('_');
      final otherUserId = parts.firstWhere(
        (id) => id != _currentUserId,
        orElse: () => '',
      );
      if (otherUserId.isNotEmpty) {
        await refreshConversation(otherUserId);
      }
    }
  }

  // =========================================================================
  // SignalR Event Handlers
  // =========================================================================

  void _onReceiveMessage(List<Object?>? parameters) {
    if (parameters == null || parameters.isEmpty) return;
    try {
      final data = parameters[0] as Map<String, dynamic>;
      final message = Message.fromJson(data);

      // Cache it
      final otherId = message.senderId == _currentUserId
          ? message.receiverId
          : message.senderId;
      final convId = _getConversationId(_currentUserId!, otherId);
      _conversationCache.putIfAbsent(convId, () => []);

      // Deduplicate
      if (!_conversationCache[convId]!.any((m) => m.id == message.id)) {
        _conversationCache[convId]!.add(message);
        _messageController.add(message);
      }

      if (kDebugMode) print('📨 Received: ${message.content}');
    } catch (e) {
      if (kDebugMode) print('❌ _onReceiveMessage error: $e');
    }
  }

  void _onMessageSent(List<Object?>? parameters) {
    if (parameters == null || parameters.isEmpty) return;
    try {
      final data = parameters[0] as Map<String, dynamic>;
      final message = Message.fromJson(data);

      final convId =
          _getConversationId(_currentUserId!, message.receiverId);
      _conversationCache.putIfAbsent(convId, () => []);

      // Replace optimistic message with server-confirmed one
      final idx = _conversationCache[convId]!.indexWhere(
        (m) =>
            m.content == message.content &&
            m.senderId == message.senderId &&
            m.id.startsWith('local_'),
      );

      if (idx != -1) {
        _conversationCache[convId]![idx] = message;
      } else if (!_conversationCache[convId]!.any((m) => m.id == message.id)) {
        _conversationCache[convId]!.add(message);
      }

      if (kDebugMode) print('✅ Confirmed: ${message.id}');
    } catch (e) {
      if (kDebugMode) print('❌ _onMessageSent error: $e');
    }
  }

  void _onMessageRead(List<Object?>? parameters) {
    if (parameters == null || parameters.isEmpty) return;
    try {
      final messageId = parameters[0].toString();
      for (final conv in _conversationCache.values) {
        final idx = conv.indexWhere((m) => m.id == messageId);
        if (idx != -1) {
          conv[idx] = conv[idx].copyWith(isRead: true, readAt: DateTime.now());
          _readReceiptController.add(messageId);
          break;
        }
      }
      if (kDebugMode) print('👁️ MessageRead: $messageId');
    } catch (e) {
      if (kDebugMode) print('❌ _onMessageRead error: $e');
    }
  }

  void _onTypingChanged(List<Object?>? parameters) {
    if (parameters == null || parameters.isEmpty) return;
    try {
      final data = parameters[0] as Map<String, dynamic>;
      _typingController.add(data);
      if (kDebugMode) {
        print('⌨️ TypingChanged: userId=${data['userId']} isTyping=${data['isTyping']}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ _onTypingChanged error: $e');
    }
  }

  void _onHubError(List<Object?>? parameters) {
    if (parameters == null || parameters.isEmpty) return;
    final error = parameters[0]?.toString() ?? 'Unknown error';
    _connectionStatusController.add('Error: $error');
    if (kDebugMode) print('❌ Hub error: $error');
  }

  // =========================================================================
  // Send Message (with offline queue)
  // =========================================================================

  /// Send a message. If offline, queues it for later delivery.
  /// Returns the optimistic local [Message] immediately.
  Future<Message?> sendMessage(
    String receiverId,
    String content, {
    MessageType type = MessageType.text,
  }) async {
    if (_currentUserId == null || _authToken == null) {
      if (kDebugMode) print('❌ sendMessage: not authenticated');
      return null;
    }

    // Create optimistic local message
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = Message(
      id: localId,
      senderId: _currentUserId!,
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
      type: type,
    );

    // Add to cache immediately
    final convId = _getConversationId(_currentUserId!, receiverId);
    _conversationCache.putIfAbsent(convId, () => []);
    _conversationCache[convId]!.add(optimistic);
    _messageController.add(optimistic);

    // Try to send via SignalR
    if (isConnected && _hubConnection != null) {
      try {
        await _hubConnection!
            .invoke('SendMessage', args: [receiverId, content, type.index]);
        if (kDebugMode) print('📤 Sent via SignalR: $content');
        return optimistic;
      } catch (e) {
        if (kDebugMode) print('⚠️ SignalR send failed, trying REST: $e');
      }
    }

    // Try REST fallback
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/messages'),
            headers: {
              'Authorization': 'Bearer $_authToken',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'receiverId': receiverId,
              'content': content,
              'type': type.index,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final confirmed = Message.fromJson(json.decode(response.body));
        // Replace optimistic with confirmed
        final idx =
            _conversationCache[convId]!.indexWhere((m) => m.id == localId);
        if (idx != -1) _conversationCache[convId]![idx] = confirmed;
        if (kDebugMode) print('📤 Sent via REST: $content');
        return confirmed;
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ REST send failed, queuing offline: $e');
    }

    // Both failed — queue for later
    _enqueue(PendingMessage(
      localId: localId,
      receiverId: receiverId,
      content: content,
      type: type,
      createdAt: DateTime.now(),
    ));

    return optimistic;
  }

  // =========================================================================
  // Offline Queue
  // =========================================================================

  void _enqueue(PendingMessage pending) {
    _pendingQueue.add(pending);
    _savePendingQueue();
    if (kDebugMode) {
      print('📥 Queued offline: ${pending.content} '
          '(queue size: ${_pendingQueue.length})');
    }
  }

  /// Flush pending messages — called periodically and on reconnect.
  Future<void> _flushPendingQueue() async {
    if (_isFlushing || _pendingQueue.isEmpty) return;
    if (_currentUserId == null || _authToken == null) return;

    _isFlushing = true;

    final toRemove = <String>[];

    for (final pending in List<PendingMessage>.from(_pendingQueue)) {
      if (pending.retryCount >= _maxRetries) {
        toRemove.add(pending.localId);
        if (kDebugMode) {
          print('❌ Dropped after $_maxRetries retries: ${pending.content}');
        }
        continue;
      }

      bool sent = false;

      // Try SignalR first
      if (isConnected && _hubConnection != null) {
        try {
          await _hubConnection!.invoke('SendMessage',
              args: [pending.receiverId, pending.content, pending.type.index]);
          sent = true;
        } catch (_) {}
      }

      // Try REST fallback
      if (!sent) {
        try {
          final response = await http
              .post(
                Uri.parse('$baseUrl/api/messages'),
                headers: {
                  'Authorization': 'Bearer $_authToken',
                  'Content-Type': 'application/json',
                },
                body: json.encode({
                  'receiverId': pending.receiverId,
                  'content': pending.content,
                  'type': pending.type.index,
                }),
              )
              .timeout(const Duration(seconds: 10));

          sent =
              response.statusCode == 200 || response.statusCode == 201;
        } catch (_) {}
      }

      if (sent) {
        toRemove.add(pending.localId);
        if (kDebugMode) {
          print('✅ Flushed queued message: ${pending.content}');
        }
      } else {
        pending.retryCount++;
      }
    }

    _pendingQueue.removeWhere((p) => toRemove.contains(p.localId));
    await _savePendingQueue();
    _isFlushing = false;

    if (_pendingQueue.isNotEmpty && kDebugMode) {
      print('📥 ${_pendingQueue.length} messages still queued');
    }
  }

  Future<void> _loadPendingQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingQueueKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = json.decode(raw);
        _pendingQueue = list
            .map((e) => PendingMessage.fromJson(e as Map<String, dynamic>))
            .toList();
        if (kDebugMode && _pendingQueue.isNotEmpty) {
          print('📥 Restored ${_pendingQueue.length} pending messages from disk');
        }
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Failed to load pending queue: $e');
      _pendingQueue = [];
    }
  }

  Future<void> _savePendingQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = json.encode(_pendingQueue.map((p) => p.toJson()).toList());
      await prefs.setString(_pendingQueueKey, raw);
    } catch (e) {
      if (kDebugMode) print('⚠️ Failed to save pending queue: $e');
    }
  }

  /// The number of messages waiting to be sent.
  int get pendingCount => _pendingQueue.length;

  /// Whether there are messages in the offline queue.
  bool get hasPendingMessages => _pendingQueue.isNotEmpty;

  // =========================================================================
  // Conversation Fetch (REST)
  // =========================================================================

  /// Get conversation history from the server.
  Future<List<Message>> getConversation(
    String otherUserId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/messages/conversation/$otherUserId?page=$page&pageSize=$pageSize'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> messagesJson = json.decode(response.body);
        final messages =
            messagesJson.map((j) => Message.fromJson(j)).toList();

        final convId = _getConversationId(_currentUserId!, otherUserId);
        _conversationCache[convId] = messages.reversed.toList();
        _hasConnectionIssue = false;

        return messages;
      } else {
        if (kDebugMode) print('❌ getConversation: ${response.statusCode}');
        return _getCachedOrEmpty(otherUserId);
      }
    } catch (e) {
      if (kDebugMode) print('❌ getConversation error: $e');
      return _getCachedOrEmpty(otherUserId);
    }
  }

  /// Get all conversation summaries.
  Future<List<ConversationSummary>> getConversations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/messages/conversations'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        _hasConnectionIssue = false;
        return list
            .map((j) => ConversationSummary.fromJson(j))
            .toList();
      } else {
        if (!_hasConnectionIssue && kDebugMode) {
          print('❌ getConversations: ${response.statusCode}');
        }
        _hasConnectionIssue = true;
        return [];
      }
    } catch (e) {
      if (!_hasConnectionIssue && kDebugMode) {
        print('❌ getConversations error: $e');
      }
      _hasConnectionIssue = true;
      return [];
    }
  }

  /// Fetch new messages for a conversation and notify listeners of new ones.
  Future<void> refreshConversation(String otherUserId) async {
    final messages = await getConversation(otherUserId);
    final convId = _getConversationId(_currentUserId!, otherUserId);
    final cached = _conversationCache[convId] ?? [];

    for (final message in messages) {
      final isNew = !cached.any((m) => m.id == message.id);
      if (isNew && message.senderId != _currentUserId) {
        _messageController.add(message);
      }
    }
  }

  // =========================================================================
  // Typing Indicator
  // =========================================================================

  /// Send typing indicator to the other user.
  /// [matchId] is the conversation/match identifier.
  Future<void> sendTyping(String matchId, bool isTyping) async {
    if (!this.isConnected || _hubConnection == null) return;
    try {
      await _hubConnection!.invoke('Typing', args: [matchId, isTyping]);
    } catch (e) {
      if (kDebugMode) print('⚠️ sendTyping error: $e');
    }
  }

  // =========================================================================
  // Mark as Read
  // =========================================================================

  Future<void> markAsRead(String messageId) async {
    // Update local cache first
    for (final conv in _conversationCache.values) {
      final idx = conv.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        conv[idx] = conv[idx].copyWith(isRead: true, readAt: DateTime.now());
        break;
      }
    }

    // Try SignalR
    if (isConnected && _hubConnection != null) {
      try {
        await _hubConnection!
            .invoke('MarkAsRead', args: [int.tryParse(messageId) ?? messageId]);
        return;
      } catch (_) {}
    }

    // REST fallback
    try {
      await http.post(
        Uri.parse('$baseUrl/api/messages/$messageId/read'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      if (kDebugMode) print('❌ markAsRead error: $e');
    }
  }

  // =========================================================================
  // Cache Helpers
  // =========================================================================

  /// Get cached messages for a conversation.
  List<Message> getCachedMessages(String otherUserId) {
    final convId = _getConversationId(_currentUserId!, otherUserId);
    return _conversationCache[convId] ?? [];
  }

  List<Message> _getCachedOrEmpty(String otherUserId) {
    final convId = _getConversationId(_currentUserId!, otherUserId);
    return _conversationCache[convId] ?? [];
  }

  String _getConversationId(String userId1, String userId2) {
    final users = [userId1, userId2]..sort();
    return '${users[0]}_${users[1]}';
  }

  // =========================================================================
  // Connection State
  // =========================================================================

  void _setConnectionState(ConnectionState state) {
    _connectionState = state;
    final label = switch (state) {
      ConnectionState.connected => 'Connected',
      ConnectionState.connecting => 'Connecting...',
      ConnectionState.reconnecting => 'Reconnecting...',
      ConnectionState.disconnected => 'Disconnected',
    };
    _connectionStatusController.add(label);
  }

  // =========================================================================
  // Cleanup
  // =========================================================================

  /// Disconnect and clean up timers. Call on logout.
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _pollingTimer?.cancel();
    _flushTimer?.cancel();

    try {
      await _hubConnection?.stop();
    } catch (_) {}

    _setConnectionState(ConnectionState.disconnected);
    _reconnectAttempt = 0;
    _usePollingFallback = false;

    if (kDebugMode) print('👋 MessagingService disconnected');
  }

  /// Dispose all streams and timers. Call on app shutdown.
  void dispose() {
    _reconnectTimer?.cancel();
    _pollingTimer?.cancel();
    _flushTimer?.cancel();
    _messageController.close();
    _connectionStatusController.close();
    _typingController.close();
    _readReceiptController.close();
    _hubConnection?.stop();
  }
}

/// Conversation summary model.
class ConversationSummary {
  final String conversationId;
  final Message lastMessage;
  final int unreadCount;
  final String otherUserId;

  ConversationSummary({
    required this.conversationId,
    required this.lastMessage,
    required this.unreadCount,
    required this.otherUserId,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) =>
      ConversationSummary(
        conversationId: json['conversationId'] ?? '',
        lastMessage: Message.fromJson(json['lastMessage'] ?? {}),
        unreadCount: json['unreadCount'] ?? 0,
        otherUserId: json['otherUserId'] ?? '',
      );
}
