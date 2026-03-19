import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/enhanced_chat_screen.dart';
import 'package:dejtingapp/models.dart';
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

/// A message from the other user with a moderation flag set.
Message _flaggedMessage() => Message(
      id: 'msg-flagged-1',
      senderId: 'user-2',
      receiverId: 'user-1',
      content: 'This message is flagged',
      timestamp: DateTime(2026, 3, 15, 10, 0),
      moderationFlag: 'inappropriate',
    );

/// A normal message with no moderation flag.
Message _normalMessage() => Message(
      id: 'msg-normal-1',
      senderId: 'user-2',
      receiverId: 'user-1',
      content: 'Hello there!',
      timestamp: DateTime(2026, 3, 15, 9, 55),
    );

void main() {
  setUpAll(() => setupTestHttpOverrides());

  group('EnhancedChatScreen safety amber warning', () {
    testWidgets('renders amber warning icon for a flagged message',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: EnhancedChatScreen(
            match: _dummyMatch(),
            initialMessages: [_flaggedMessage()],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // The amber warning icon should be present.
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('renders amber warning text for a flagged message',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: EnhancedChatScreen(
            match: _dummyMatch(),
            initialMessages: [_flaggedMessage()],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // The warning label should contain the community-guidelines text.
      expect(
        find.textContaining('community guidelines'),
        findsOneWidget,
      );
    });

    testWidgets('does not render amber warning for a normal message',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: EnhancedChatScreen(
            match: _dummyMatch(),
            initialMessages: [_normalMessage()],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // No warning icon or text should appear for a clean message.
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      expect(find.textContaining('community guidelines'), findsNothing);
    });

    testWidgets('flagged and normal messages rendered side by side',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: EnhancedChatScreen(
            match: _dummyMatch(),
            initialMessages: [_normalMessage(), _flaggedMessage()],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Message content from both messages is visible.
      expect(find.textContaining('Hello there!'), findsOneWidget);
      expect(find.textContaining('This message is flagged'), findsOneWidget);

      // Exactly one warning indicator (only the flagged one).
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('back navigation works from chat screen', (tester) async {
      // Push the chat screen on top of a base route so the back button appears.
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('open-chat'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EnhancedChatScreen(
                    match: _dummyMatch(),
                    initialMessages: [],
                  ),
                ),
              ),
              child: const Text('Open Chat'),
            ),
          ),
        ),
      );

      // Navigate into the chat screen.
      await tester.tap(find.byKey(const Key('open-chat')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Chat screen should now be on screen — use byWidgetPredicate for reliability.
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && (w as Semantics).properties.label == 'screen:chat',
        ),
        findsOneWidget,
      );

      // Tap the system back button to pop the route.
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Chat screen is gone; the base route button is visible again.
      expect(find.bySemanticsLabel('screen:chat'), findsNothing);
      expect(find.byKey(const Key('open-chat')), findsOneWidget);
    });
  });
}
