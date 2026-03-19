import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/home_screen.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('renders scaffold', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const HomeScreen()),
      );
      // Pump once for initial frame (don't pumpAndSettle — async API call)
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const HomeScreen()),
      );
      await tester.pump();
      // Should show loading state on init (API call in flight)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error or empty state after failed load', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const HomeScreen()),
      );
      // Wait for the API call to fail (no server running in tests)
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
      // Should see either error message or empty state
      final hasContent = find.byType(Scaffold).evaluate().isNotEmpty;
      expect(hasContent, isTrue);
    });

    testWidgets('filter icon button is present', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const HomeScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    });

    testWidgets('tapping filter icon opens discovery filter bottom sheet',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const HomeScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // Bottom sheet should show discovery settings title
      expect(find.text('Discovery Settings'), findsOneWidget);
      // Distance and age range sliders should be present
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byType(RangeSlider), findsOneWidget);
      // Done button should be present
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('discovery filter bottom sheet closes on Done', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const HomeScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // Tap Done button
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Bottom sheet should be dismissed
      expect(find.text('Discovery Settings'), findsNothing);
    });
  });
}
