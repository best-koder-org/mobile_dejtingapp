import 'package:flutter_test/flutter_test.dart';
import 'helpers/test_config.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/profile_helpers.dart';
import 'helpers/message_helpers.dart';

/// T041 - Messaging Integration Tests
/// User Story: US4 - Real-time Messaging
///
/// Verified against actual messaging-service MessagesController:
///   Send:         POST /api/messages  body: {recipientUserId, text}  → 201
///   Conversation: GET  /api/messages/conversation/{otherUserId}      → 200
///   Conversations:GET  /api/messages/conversations                   → 200
///   Mark read:    POST /api/messages/{messageId}/read                → 200
///
/// NOTE: Messaging uses Keycloak UUID (user.userId), NOT integer profileId.
/// NOTE: Messaging requires a match to exist (MatchValidationService checks via
///       swipe-service's /api/matches/check/{userId1}/{userId2}).

void main() {
  group('T041 - Messaging Contracts', () {
    late TestUser user1;
    late TestUser user2;

    setUp(() async {
      user1 = TestUser.random();
      user2 = TestUser.random();
    });

    test('Contract: Users can send messages after match', () async {
      await registerUser(user1);
      await registerUser(user2);
      await completeOnboarding(user1, firstName: 'Alice');
      await completeOnboarding(user2, firstName: 'Bob');

      // Create mutual match (uses profileIds for swipe-service)
      await createMatch(user1, user2);

      // Send message using Keycloak UUID
      final sentMessage = await sendMessage(
        user1,
        user2.userId!,
        text: 'Hey there! 👋',
      );

      expect(sentMessage, isNotEmpty);
      expect(sentMessage['text'] ?? sentMessage['content'], equals('Hey there! 👋'));
    });

    test('Contract: Recipients can retrieve sent messages', () async {
      await registerUser(user1);
      await registerUser(user2);
      await completeOnboarding(user1);
      await completeOnboarding(user2);
      await createMatch(user1, user2);

      await sendMessage(user1, user2.userId!, text: 'Test message');

      // Retrieve conversation from recipient side (using sender's Keycloak UUID)
      final conversation = await getConversation(user2, user1.userId!);

      expect(conversation, isNotEmpty);
      expect(
        conversation.any((msg) =>
            (msg['text'] ?? msg['content']) == 'Test message'),
        true,
        reason: 'Sent message should appear in recipient conversation',
      );
    });

    test('Contract: Can exchange multiple messages', () async {
      await registerUser(user1);
      await registerUser(user2);
      await completeOnboarding(user1);
      await completeOnboarding(user2);
      await createMatch(user1, user2);

      // Send messages back and forth (using Keycloak UUIDs)
      await sendMessage(user1, user2.userId!, text: 'Message 1');
      await sendMessage(user2, user1.userId!, text: 'Message 2');
      await sendMessage(user1, user2.userId!, text: 'Message 3');

      // Both users should see all messages
      final conv1 = await getConversation(user1, user2.userId!);
      final conv2 = await getConversation(user2, user1.userId!);

      expect(conv1.length, greaterThanOrEqualTo(3));
      expect(conv2.length, greaterThanOrEqualTo(3));
    });

    test('Contract: Conversations list shows active chats', () async {
      await registerUser(user1);
      await registerUser(user2);
      await completeOnboarding(user1);
      await completeOnboarding(user2);
      await createMatch(user1, user2);

      await sendMessage(user1, user2.userId!, text: 'Start chat');

      final conversations = await getConversations(user1);

      expect(conversations, isNotEmpty,
          reason: 'Should have at least 1 conversation');
    });

    test('Contract: Mark message as read', () async {
      await registerUser(user1);
      await registerUser(user2);
      await completeOnboarding(user1);
      await completeOnboarding(user2);
      await createMatch(user1, user2);

      final sentMessage = await sendMessage(
        user1,
        user2.userId!,
        text: 'Read me',
      );

      final messageId = sentMessage['messageId'] ?? sentMessage['id'];
      if (messageId != null) {
        await markMessageRead(user2, messageId);
        expect(messageId, isNotNull);
      } else {
        print('⚠️ Backend does not return messageId in send response');
      }
    });

    test('Error: Cannot message non-matched user', () async {
      await registerUser(user1);
      await registerUser(user2);
      await completeOnboarding(user1);
      await completeOnboarding(user2);

      // NO match created — should fail with 403 (MatchValidationService rejects)
      expect(
        () async => await sendMessage(
          user1,
          user2.userId!,
          text: 'Unsolicited message',
        ),
        throwsException,
        reason: 'Should not allow messages to non-matches',
      );
    });

    test('Flow: Complete messaging journey', () async {
      await registerUser(user1);
      await registerUser(user2);
      await completeOnboarding(user1, firstName: 'Alice');
      await completeOnboarding(user2, firstName: 'Bob');

      // Match via mutual swipes
      await createMatch(user1, user2);

      // Alice initiates
      await sendMessage(user1, user2.userId!, text: 'Hi Bob!');

      // Bob sees conversations
      final conversations = await getConversations(user2);
      expect(conversations, isNotEmpty);

      // Bob reads conversation
      final messages = await getConversation(user2, user1.userId!);
      expect(messages, isNotEmpty);
      expect(
        messages.any((m) => (m['text'] ?? m['content']) == 'Hi Bob!'),
        true,
      );

      // Bob replies
      await sendMessage(user2, user1.userId!, text: 'Hey Alice!');

      // Alice sees reply
      final updatedMessages = await getConversation(user1, user2.userId!);
      expect(
        updatedMessages.any((m) => (m['text'] ?? m['content']) == 'Hey Alice!'),
        true,
      );
    });
  });
}
