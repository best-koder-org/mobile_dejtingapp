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
        find.bySemanticsLabel('screen:chat'),
        findsOneWidget,
      );
    });
  });
}
