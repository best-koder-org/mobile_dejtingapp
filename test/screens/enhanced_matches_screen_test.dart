import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/enhanced_matches_screen.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('EnhancedMatchesScreen', () {
    testWidgets('renders scaffold', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const EnhancedMatchesScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('has TabBar with 2 tabs', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const EnhancedMatchesScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(2));
    });

    testWidgets('shows loading or content after init', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const EnhancedMatchesScreen()),
      );
      await tester.pump(const Duration(seconds: 1));
      final hasContent = find.byType(Scaffold).evaluate().isNotEmpty;
      expect(hasContent, isTrue);
    });

    testWidgets(
        'connection status badge shows refresh icon and is tappable when auth fails',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const EnhancedMatchesScreen()),
      );
      // Allow async messaging init to complete (no real auth in tests →
      // status will be 'Auth required' or 'Disconnected', both retryable).
      await tester.pump(const Duration(seconds: 1));

      // A refresh icon must be visible as a hint that the badge is retryable
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // The retryable badge must be wrapped in a GestureDetector
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets(
        'tapping the retryable badge transitions connection status to Connecting...',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const EnhancedMatchesScreen()),
      );
      // Allow async messaging init to complete (no real auth → retryable state)
      await tester.pump(const Duration(seconds: 1));

      // Tap the refresh icon which is only present in retryable states
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Immediately after tap the status must be reset to 'Connecting...'
      expect(find.text('Connecting...'), findsOneWidget);
    });

    testWidgets('has screen:matches semantics label', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const EnhancedMatchesScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.bySemanticsLabel('screen:matches'),
        findsOneWidget,
      );
    });
  });
}
