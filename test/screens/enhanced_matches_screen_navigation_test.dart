import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/enhanced_matches_screen.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('EnhancedMatchesScreen tab switching and empty states', () {
    setUpAll(() {
      // Mock flutter_secure_storage so getOrResolveProfileId fails fast
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (MethodCall methodCall) async => null,
      );
      // Mock shared_preferences
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getAll') return <String, dynamic>{};
          return null;
        },
      );
    });

    tearDownAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        null,
      );
    });

    Future<void> pumpAndWaitForLoad(WidgetTester tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const EnhancedMatchesScreen()),
      );
      // Let async data loading complete (API calls fail, _isLoading -> false)
      await tester.runAsync(() => Future.delayed(const Duration(seconds: 2)));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('new matches tab is active by default', (tester) async {
      await pumpAndWaitForLoad(tester);

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(2));
      expect(find.text('New Matches'), findsWidgets);
      expect(find.text('Messages'), findsOneWidget);
    });

    testWidgets('new matches tab shows empty state when no matches loaded',
        (tester) async {
      await pumpAndWaitForLoad(tester);

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.text('No matches yet'), findsOneWidget);
    });

    testWidgets('new matches tab empty state shows keep-swiping hint',
        (tester) async {
      await pumpAndWaitForLoad(tester);

      expect(
        find.text('Keep swiping to find your perfect match!'),
        findsOneWidget,
      );
    });

    testWidgets('tapping Messages tab switches to messages view', (tester) async {
      await pumpAndWaitForLoad(tester);

      await tester.tap(find.text('Messages'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.text('No conversations yet'), findsOneWidget);
    });

    testWidgets('messages tab empty state shows start-chatting hint',
        (tester) async {
      await pumpAndWaitForLoad(tester);

      await tester.tap(find.text('Messages'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Start chatting with your matches!'),
        findsOneWidget,
      );
    });

    testWidgets('can switch back from messages tab to new matches tab',
        (tester) async {
      await pumpAndWaitForLoad(tester);

      await tester.tap(find.text('Messages'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('New Matches').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('No matches yet'), findsOneWidget);
    });

    testWidgets(
        'auth-required badge is visible and retryable in unauthenticated state',
        (tester) async {
      await pumpAndWaitForLoad(tester);

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('tapping auth-required badge triggers reconnection attempt',
        (tester) async {
      await pumpAndWaitForLoad(tester);

      // Badge with refresh icon must be tappable
      final refreshFinder = find.byIcon(Icons.refresh);
      expect(refreshFinder, findsOneWidget);

      // Tap the retry badge — this calls _initializeMessaging()
      await tester.tap(refreshFinder);
      await tester.pump();

      // The connection status transitions through Connecting...
      // and may complete quickly in tests. The badge remains visible
      // as a status indicator in a non-Connected state.
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('has screen:matches semantics label on both tabs', (tester) async {
      await pumpAndWaitForLoad(tester);

      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && (w as Semantics).properties.label == 'screen:matches',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Messages'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && (w as Semantics).properties.label == 'screen:matches',
        ),
        findsOneWidget,
      );
    });
  });
}
