import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/enhanced_matches_screen.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('EnhancedMatchesScreen tab switching and empty states', () {
    testWidgets('new matches tab is active by default', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const EnhancedMatchesScreen()),
      );
      await tester.pump(const Duration(seconds: 1));

      // TabBar with 2 tabs must be present
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(2));

      // Both tab labels are visible in the tab bar
      expect(find.text('New Matches'), findsWidgets);
      expect(find.text('Messages'), findsOneWidget);
    });

    testWidgets('new matches tab shows empty state when no matches loaded',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const EnhancedMatchesScreen()),
      );
      // Allow async data load to complete (API unavailable in tests → empty)
      await tester.pump(const Duration(seconds: 1));

      // Empty-state icon and headline are visible on the New Matches tab
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.text('No matches yet'), findsOneWidget);
    });

    testWidgets('new matches tab empty state shows keep-swiping hint',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const EnhancedMatchesScreen()),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.text('Keep swiping to find your perfect match!'),
        findsOneWidget,
      );
    });

    testWidgets('tapping Messages tab switches to messages view', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const EnhancedMatchesScreen()),
      );
      await tester.pump(const Duration(seconds: 1));

      // Tap the Messages tab
      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();

      // Messages empty-state icon and headline are now visible
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.text('No conversations yet'), findsOneWidget);
    });

    testWidgets('messages tab empty state shows start-chatting hint',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const EnhancedMatchesScreen()),
      );
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();

      expect(
        find.text('Start chatting with your matches!'),
        findsOneWidget,
      );
    });

    testWidgets('can switch back from messages tab to new matches tab',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const EnhancedMatchesScreen()),
      );
      await tester.pump(const Duration(seconds: 1));

      // Switch to Messages
      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();

      // Switch back to New Matches
      await tester.tap(find.text('New Matches').first);
      await tester.pumpAndSettle();

      // New Matches empty state is visible again
      expect(find.text('No matches yet'), findsOneWidget);
    });

    testWidgets(
        'auth-required badge is visible and retryable in unauthenticated state',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const EnhancedMatchesScreen()),
      );
      // No real auth in tests → status will be Auth required or Disconnected
      await tester.pump(const Duration(seconds: 1));

      // Refresh icon is the visual hint that the badge is retryable
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // The badge must be tappable (wrapped in GestureDetector)
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('tapping auth-required badge transitions status to Connecting',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const EnhancedMatchesScreen()),
      );
      await tester.pump(const Duration(seconds: 1));

      // Tap the refresh icon present on retryable connection badges
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Status must immediately reset to the in-progress connecting label
      expect(find.text('Connecting...'), findsOneWidget);
    });

    testWidgets('has screen:matches semantics label on both tabs', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const EnhancedMatchesScreen()),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.bySemanticsLabel('screen:matches'), findsOneWidget);

      // Semantics label persists after switching tabs
      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('screen:matches'), findsOneWidget);
    });
  });
}
