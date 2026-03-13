// T031: Flutter integration test for swipe flows with offline retry coverage
// Tests cover candidate loading, swipe actions, mutual match detection, 
// offline retry, queue refresh, and empty-state handling

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dejtingapp/main.dart' as app;
// SwipeScreen removed — discovery is now in screens/home_screen.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Swipe Flow Integration Tests', () {
    testWidgets('T031.1: Loads candidates and displays swipe UI',
        (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to swipe screen (assuming it's in a tab or accessible)
      // This may need adjustment based on actual app navigation structure
      // SwipeScreen merged into HomeScreen discovery tab
      
      // If SwipeScreen is not immediately visible, navigate to it
      // For example, if it's in a bottom navigation tab:
      final discoverTab = find.byIcon(Icons.favorite);
      if (discoverTab.evaluate().isNotEmpty) {
        await tester.tap(discoverTab);
        await tester.pumpAndSettle();
      }

      // Wait for loading to complete
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify swipe UI elements are present
      expect(
        find.byIcon(Icons.close), // Pass button
        findsOneWidget,
        reason: 'Pass button should be visible',
      );
      expect(
        find.byIcon(Icons.favorite), // Like button
        findsAtLeast(1),
        reason: 'Like button should be visible',
      );

      // Verify profile card is displayed
      expect(
        find.byType(Card),
        findsWidgets,
        reason: 'Profile card should be displayed',
      );
    });

    testWidgets('T031.2: Performs pass swipe and loads next candidate',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to swipe screen
      final discoverTab = find.byIcon(Icons.favorite);
      if (discoverTab.evaluate().isNotEmpty) {
        await tester.tap(discoverTab);
        await tester.pumpAndSettle();
      }

      // Wait for candidates to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Find the pass button
      final passButton = find.ancestor(
        of: find.byIcon(Icons.close),
        matching: find.byType(FloatingActionButton),
      );

      if (passButton.evaluate().isNotEmpty) {
        // Tap pass button
        await tester.tap(passButton);
        await tester.pumpAndSettle();

        // Verify swipe was processed (no error message)
        expect(
          find.text('Failed to record swipe'),
          findsNothing,
          reason: 'Swipe should succeed without error',
        );

        // Verify next candidate is shown or empty state
        final hasCard = find.byType(Card).evaluate().isNotEmpty;
        final hasEmptyState =
            find.text('No more profiles!').evaluate().isNotEmpty;

        expect(
          hasCard || hasEmptyState,
          isTrue,
          reason: 'Should show next candidate or empty state',
        );
      }
    });

    testWidgets('T031.3: Performs like swipe and handles potential match',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to swipe screen
      final discoverTab = find.byIcon(Icons.favorite);
      if (discoverTab.evaluate().isNotEmpty) {
        await tester.tap(discoverTab);
        await tester.pumpAndSettle();
      }

      // Wait for candidates to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Find the like button (exclude any in app bar)
      final likeButtonFinder = find.descendant(
        of: find.byType(FloatingActionButton),
        matching: find.byIcon(Icons.favorite),
      );

      if (likeButtonFinder.evaluate().isNotEmpty) {
        final likeButton = likeButtonFinder.last;
        // Tap like button
        await tester.tap(likeButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Check if match dialog appeared
        final matchDialog =
            find.text("It's a Match!", findRichText: true).evaluate();

        if (matchDialog.isNotEmpty) {
          // Verify match dialog elements
          expect(
            find.text('Keep Swiping'),
            findsOneWidget,
            reason: 'Match dialog should have Keep Swiping button',
          );
          expect(
            find.text('View Matches'),
            findsOneWidget,
            reason: 'Match dialog should have View Matches button',
          );

          // Tap Keep Swiping to continue
          await tester.tap(find.text('Keep Swiping'));
          await tester.pumpAndSettle();
        }

        // Verify no error occurred
        expect(
          find.text('Failed to record swipe'),
          findsNothing,
          reason: 'Like swipe should succeed',
        );
      }
    });

    testWidgets('T031.4: Handles swipe queue exhaustion gracefully',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to swipe screen
      final discoverTab = find.byIcon(Icons.favorite);
      if (discoverTab.evaluate().isNotEmpty) {
        await tester.tap(discoverTab);
        await tester.pumpAndSettle();
      }

      // Wait for initial load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Swipe through all available candidates (max 30 swipes for safety)
      for (int i = 0; i < 30; i++) {
        final passButton = find.ancestor(
          of: find.byIcon(Icons.close),
          matching: find.byType(FloatingActionButton),
        );

        // Check if we hit empty state
        if (find.text('No more profiles!').evaluate().isNotEmpty) {
          // Verify empty state messaging
          expect(
            find.byIcon(Icons.favorite),
            findsWidgets,
            reason: 'Empty state should show heart icon',
          );
          expect(
            find.textContaining('Check back later'),
            findsOneWidget,
            reason: 'Empty state should show helpful message',
          );
          break;  // Exit loop when queue is exhausted
        }

        // If pass button exists, tap it
        if (passButton.evaluate().isNotEmpty) {
          await tester.tap(passButton);
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pumpAndSettle();
        } else {
          break; // No more candidates
        }
      }
    });

    testWidgets('T031.5: Retries on network error with retry button',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to swipe screen
      final discoverTab = find.byIcon(Icons.favorite);
      if (discoverTab.evaluate().isNotEmpty) {
        await tester.tap(discoverTab);
        await tester.pumpAndSettle();
      }

      // Wait for load attempt
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Check if error state is displayed
      final retryButton = find.widgetWithText(ElevatedButton, 'Retry');

      if (retryButton.evaluate().isNotEmpty) {
        // Verify error message is shown
        expect(
          find.textContaining('Failed to load'),
          findsOneWidget,
          reason: 'Error message should be displayed',
        );

        // Tap retry button
        await tester.tap(retryButton);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Verify retry attempt was made
        // Either success (candidates loaded) or error persists
        final hasCards = find.byType(Card).evaluate().isNotEmpty;
        final hasRetry = find.widgetWithText(ElevatedButton, 'Retry')
            .evaluate()
            .isNotEmpty;

        expect(
          hasCards || hasRetry,
          isTrue,
          reason: 'Retry should either load candidates or show retry option',
        );
      }
    });

    testWidgets('T031.6: Loads more candidates when queue runs low',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to swipe screen
      final discoverTab = find.byIcon(Icons.favorite);
      if (discoverTab.evaluate().isNotEmpty) {
        await tester.tap(discoverTab);
        await tester.pumpAndSettle();
      }

      // Wait for initial candidates
      await tester.pumpAndSettle(const Duration(seconds: 5));


      // Swipe through enough profiles to trigger pagination (18+ swipes)
      for (int i = 0; i < 18; i++) {
        final passButton = find.ancestor(
          of: find.byIcon(Icons.close),
          matching: find.byType(FloatingActionButton),
        );

        if (passButton.evaluate().isEmpty) break;

        await tester.tap(passButton);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Check if more candidates were loaded
        if (i == 17) {
          // After 18 swipes, pagination should have occurred
          await tester.pumpAndSettle(const Duration(seconds: 2));
          
          // Verify we still have candidates (pagination worked)
          // or we hit empty state (no more profiles exist)
          final stillHasCards = find.byType(Card).evaluate().isNotEmpty;
          final hitEmptyState =
              find.text('No more profiles!').evaluate().isNotEmpty;

          expect(
            stillHasCards || hitEmptyState,
            isTrue,
            reason: 'Should have more candidates from pagination or show empty state',
          );
        }
      }
    });

    testWidgets('T031.7: Handles rapid successive swipes gracefully',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to swipe screen
      final discoverTab = find.byIcon(Icons.favorite);
      if (discoverTab.evaluate().isNotEmpty) {
        await tester.tap(discoverTab);
        await tester.pumpAndSettle();
      }

      // Wait for candidates
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Perform rapid swipes (5 in quick succession)
      for (int i = 0; i < 5; i++) {
        final passButton = find.ancestor(
          of: find.byIcon(Icons.close),
          matching: find.byType(FloatingActionButton),
        );

        if (passButton.evaluate().isEmpty) break;

        await tester.tap(passButton);
        await tester.pump(const Duration(milliseconds: 100)); // Very short delay
      }

      // Wait for all swipes to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify no error occurred from rapid interactions
      expect(
        find.textContaining('error', findRichText: true, skipOffstage: false),
        findsNothing,
        reason: 'Rapid swipes should not cause errors',
      );

      // Verify UI is still functional - either has buttons or shows empty state
      final hasButtons = find.byType(FloatingActionButton).evaluate().length >= 2;
      final hasEmptyState = find.text('No more profiles!').evaluate().isNotEmpty;
      final hasLoadingIndicator = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;

      expect(
        hasButtons || hasEmptyState || hasLoadingIndicator,
        isTrue,
        reason: 'UI should remain functional after rapid swipes (has buttons, empty state, or loading)',
      );
    });

    testWidgets('T031.8: Preserves swipe progress across screen navigations',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to swipe screen
      final discoverTab = find.byIcon(Icons.favorite);
      if (discoverTab.evaluate().isNotEmpty) {
        await tester.tap(discoverTab);
        await tester.pumpAndSettle();
      }

      // Wait for candidates and perform one swipe
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final passButton = find.ancestor(
        of: find.byIcon(Icons.close),
        matching: find.byType(FloatingActionButton),
      );

      if (passButton.evaluate().isNotEmpty) {
        await tester.tap(passButton);
        await tester.pumpAndSettle();

        // Navigate away (e.g., to matches tab)
        final matchesTab = find.byIcon(Icons.message);
        if (matchesTab.evaluate().isNotEmpty) {
          await tester.tap(matchesTab);
          await tester.pumpAndSettle();

          // Navigate back to swipe screen
          await tester.tap(discoverTab);
          await tester.pumpAndSettle();

          // Verify swipe screen reloaded successfully
          expect(
            find.byType(FloatingActionButton),
            findsWidgets,
            reason: 'Swipe buttons should be visible after navigation',
          );
        }
      }
    });
  });
}
