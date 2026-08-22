import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dejtingapp/screens/enhanced_chat_screen.dart';
import 'package:dejtingapp/models.dart';
import 'package:dejtingapp/theme/app_theme.dart';
import '../helpers/core_screen_test_helper.dart';

Match _dummyMatch() => Match(
      id: 'match-1',
      userId1: 'user-1',
      userId2: 'user-2',
      matchedAt: DateTime(2026, 3, 15),
      isActive: true,
      otherUserProfile: UserProfile(
        id: '1',
        userId: 'user-2',
        firstName: 'Bob',
        lastName: 'Smith',
        dateOfBirth: DateTime(1995, 5, 10),
        bio: 'Music lover',
        city: 'Gothenburg',
      ),
    );

void main() {
  setUpAll(() => setupTestHttpOverrides());

  group('EnhancedChatScreen', () {
    testWidgets('renders scaffold with match', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: EnhancedChatScreen(match: _dummyMatch()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('bubble colors: my messages coral, other person light',
        (tester) async {
      final mine = Message(
        id: 'm1', senderId: 'user-1', receiverId: 'user-2',
        content: 'from me', timestamp: DateTime(2026, 3, 15, 10, 0),
      );
      final theirs = Message(
        id: 'm2', senderId: 'user-2', receiverId: 'user-1',
        content: 'from them', timestamp: DateTime(2026, 3, 15, 10, 1),
      );
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: EnhancedChatScreen(
            match: _dummyMatch(),
            initialMessages: [theirs, mine],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final containers =
          tester.widgetList<Container>(find.byType(Container)).toList();
      final colors = containers
          .map((c) => (c.decoration is BoxDecoration)
              ? (c.decoration as BoxDecoration).color
              : null)
          .toSet();
      expect(colors, contains(AppTheme.chatBubbleMe),
          reason: 'my bubble should be coral');
      expect(colors, contains(AppTheme.chatBubbleOther),
          reason: 'other bubble should be light');
    });

    testWidgets('shows Yesterday header for a previous-day message',
        (tester) async {
      final old = Message(
        id: 'm-old', senderId: 'user-2', receiverId: 'user-1',
        content: 'old message',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      );
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: EnhancedChatScreen(
            match: _dummyMatch(),
            initialMessages: [old],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('Yesterday'), findsWidgets);
    });

    testWidgets('shows heart for a previously-liked message', (tester) async {
      SharedPreferences.setMockInitialValues({
        'liked_message_ids': ['msg-like-1'],
      });
      final msg = Message(
        id: 'msg-like-1', senderId: 'user-2', receiverId: 'user-1',
        content: 'hello', timestamp: DateTime(2026, 3, 15, 10, 0),
      );
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: EnhancedChatScreen(
            match: _dummyMatch(),
            initialMessages: [msg],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('double-tap adds a heart to the other user message',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final msg = Message(
        id: 'msg-like-2', senderId: 'user-2', receiverId: 'user-1',
        content: 'hello again', timestamp: DateTime(2026, 3, 15, 10, 0),
      );
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: EnhancedChatScreen(
            match: _dummyMatch(),
            initialMessages: [msg],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.favorite), findsNothing);

      final bubble = find.text('hello again');
      await tester.tap(bubble);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(bubble);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('shows other user name in app bar', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: EnhancedChatScreen(match: _dummyMatch()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('Bob'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows text input field', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: EnhancedChatScreen(match: _dummyMatch()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });

    testWidgets('empty input shows mic button instead of send', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: EnhancedChatScreen(match: _dummyMatch()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      // Mic button should be visible (via VoiceChatRecorder idle state)
      expect(find.byIcon(Icons.mic), findsOneWidget);
      // Send button should NOT be visible when text is empty
      expect(find.byIcon(Icons.send), findsNothing);
    });

    testWidgets('typing text shows send button', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: EnhancedChatScreen(match: _dummyMatch()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      // Type text into the field
      await tester.enterText(find.byType(TextField).first, 'Hello');
      await tester.pump();
      // Now send button should appear
      expect(find.byIcon(Icons.send), findsOneWidget);
      // Mic should be gone
      expect(find.byIcon(Icons.mic), findsNothing);
    });

    testWidgets('clearing text shows mic button again', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: EnhancedChatScreen(match: _dummyMatch()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      // Type and then clear
      await tester.enterText(find.byType(TextField).first, 'Hello');
      await tester.pump();
      expect(find.byIcon(Icons.send), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '');
      await tester.pump();
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.send), findsNothing);
    });

    testWidgets('has screen:chat semantics label', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: EnhancedChatScreen(match: _dummyMatch()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byWidgetPredicate((w) => w is Semantics && (w as Semantics).properties.label == 'screen:chat'),
        findsOneWidget,
      );
    });

    testWidgets('moderated message does not overflow at phone width',
        (tester) async {
      // Phone-sized view (360 logical dp wide) — reproduces the 21px overflow.
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final moderated = Message(
        id: 'mod-1', senderId: 'user-2', receiverId: 'user-1',
        content: 'hello there',
        timestamp: DateTime(2026, 3, 15, 10, 0),
        moderationFlag: 'inappropriate',
      );
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: EnhancedChatScreen(
            match: _dummyMatch(),
            initialMessages: [moderated],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // The long moderation warning must render without overflowing the bubble.
      expect(find.textContaining('may violate community'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
