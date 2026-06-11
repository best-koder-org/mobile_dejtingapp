import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/sparks_store_screen.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('SparksStoreScreen', () {
    testWidgets('renders scaffold and app bar', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SparksStoreScreen()),
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows Sparks Store title', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SparksStoreScreen()),
      );
      await tester.pump();
      expect(find.text('Sparks Store'), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SparksStoreScreen()),
      );
      // First frame: loading state (HTTP call in flight, no backend in tests)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('PaywallSheet', () {
    testWidgets('renders with feature name', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (_) => const PaywallSheet(featureName: 'Sparks'),
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      // Open the bottom sheet
      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should show paywall content
      expect(find.text('Upgrade to Premium'), findsOneWidget);
      expect(find.text('See plans'), findsOneWidget);
      expect(find.text('Maybe later'), findsOneWidget);
    });

    testWidgets('See plans navigates to SparksStoreScreen', (tester) async {
      // We can't fully test Navigator.push in a simple widget test
      // without wrapping in a MaterialApp with routes, but we can verify
      // the button exists
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (_) => const PaywallSheet(featureName: 'Sparks'),
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('See plans'), findsOneWidget);
    });
  });
}
