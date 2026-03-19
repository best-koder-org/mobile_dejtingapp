import 'package:dejtingapp/models.dart';
import 'package:dejtingapp/services/messaging_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PendingMessage', () {
    test('toJson serializes all fields with correct key names', () {
      final created = DateTime.utc(2026, 3, 19, 10, 0, 0);
      final msg = PendingMessage(
        localId: 'local_001',
        receiverId: 'user_42',
        content: 'Hello!',
        type: MessageType.text,
        createdAt: created,
        retryCount: 2,
      );

      final json = msg.toJson();
      expect(json['localId'], 'local_001');
      expect(json['recipientUserId'], 'user_42');
      expect(json['text'], 'Hello!');
      expect(json['type'], 0); // MessageType.text.index
      expect(json['retryCount'], 2);
      expect(json['createdAt'], created.toIso8601String());
    });

    test('fromJson deserializes all fields correctly', () {
      final json = {
        'localId': 'local_002',
        'receiverId': 'user_99',
        'content': 'Hi there',
        'type': 2, // MessageType.emoji
        'createdAt': '2026-01-15T08:30:00.000Z',
        'retryCount': 3,
      };

      final msg = PendingMessage.fromJson(json);
      expect(msg.localId, 'local_002');
      expect(msg.receiverId, 'user_99');
      expect(msg.content, 'Hi there');
      expect(msg.type, MessageType.emoji);
      expect(msg.retryCount, 3);
    });

    test('fromJson uses defaults for missing fields', () {
      final msg = PendingMessage.fromJson({});
      expect(msg.localId, '');
      expect(msg.receiverId, '');
      expect(msg.content, '');
      expect(msg.type, MessageType.text);
      expect(msg.retryCount, 0);
    });
  });

  group('ConversationSummary', () {
    test('fromJson parses complete summary correctly', () {
      final now = DateTime.utc(2026, 3, 19).toIso8601String();
      final json = {
        'conversationId': 'conv_123',
        'otherUserId': 'user_99',
        'unreadCount': 5,
        'lastMessage': {
          'id': 'msg_1',
          'senderId': 'user_99',
          'receiverId': 'user_42',
          'content': 'See you soon!',
          'timestamp': now,
          'isRead': false,
          'type': 0,
        },
      };

      final summary = ConversationSummary.fromJson(json);
      expect(summary.conversationId, 'conv_123');
      expect(summary.otherUserId, 'user_99');
      expect(summary.unreadCount, 5);
      expect(summary.lastMessage.content, 'See you soon!');
      expect(summary.lastMessage.senderId, 'user_99');
      expect(summary.lastMessage.receiverId, 'user_42');
    });

    test('fromJson uses defaults for missing optional fields', () {
      final summary = ConversationSummary.fromJson({
        'lastMessage': {
          'id': '',
          'senderId': '',
          'receiverId': '',
          'content': '',
          'timestamp': DateTime.now().toIso8601String(),
        },
      });
      expect(summary.conversationId, '');
      expect(summary.otherUserId, '');
      expect(summary.unreadCount, 0);
    });
  });

  group('ConnectionState', () {
    test('enum contains all four expected states', () {
      expect(ConnectionState.values, hasLength(4));
      expect(ConnectionState.values, contains(ConnectionState.disconnected));
      expect(ConnectionState.values, contains(ConnectionState.connecting));
      expect(ConnectionState.values, contains(ConnectionState.connected));
      expect(ConnectionState.values, contains(ConnectionState.reconnecting));
    });
  });

  group('MessagingService', () {
    test('factory returns the same singleton instance', () {
      final a = MessagingService();
      final b = MessagingService();
      expect(identical(a, b), isTrue);
    });

    test('starts in disconnected state before initialization', () {
      final service = MessagingService();
      expect(service.connectionState, ConnectionState.disconnected);
    });

    test('isConnected is false before initialization', () {
      final service = MessagingService();
      expect(service.isConnected, isFalse);
    });

    test('pending queue is empty before initialization', () {
      final service = MessagingService();
      expect(service.pendingCount, 0);
      expect(service.hasPendingMessages, isFalse);
    });

    test('all message streams are accessible', () {
      final service = MessagingService();
      expect(service.messageStream, isNotNull);
      expect(service.connectionStatusStream, isNotNull);
      expect(service.typingStream, isNotNull);
      expect(service.readReceiptStream, isNotNull);
    });

    test('sendMessage returns null when not authenticated', () async {
      final service = MessagingService();
      // Service not initialized — no userId or authToken set
      final result = await service.sendMessage('user_99', 'Hello');
      expect(result, isNull);
    });

    test('sendTyping does not throw when not connected', () async {
      final service = MessagingService();
      // sendTyping returns early when not connected — should not throw
      await expectLater(
        service.sendTyping('match_abc', true),
        completes,
      );
    });
  });
}
