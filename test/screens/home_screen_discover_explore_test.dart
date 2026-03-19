import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/home_screen.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('HomeScreen — Discover explore (UC1)', () {
    testWidgets('filter button has Discovery Filters tooltip', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const HomeScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // The tooltip makes the button discoverable for UI automation.
      final btn = find.byTooltip('Discovery Filters');
      expect(btn, findsOneWidget);
    });

    testWidgets('tapping filter opens sheet with sheet:discovery-settings semantics',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const HomeScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byIcon(Icons.tune_rounded));
      // Use pump() instead of pumpAndSettle() — indeterminate CircularProgressIndicator
      // keeps pumpAndSettle from ever completing.
      await tester.pump(); // start sheet animation
      await tester.pump(const Duration(milliseconds: 500)); // let it finish

      expect(
        find.bySemanticsLabel('sheet:discovery-settings'),
        findsOneWidget,
      );
    });

    testWidgets('discovery settings sheet shows required elements', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const HomeScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Discovery Settings'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byType(RangeSlider), findsOneWidget);
      expect(find.text('Show me on DejTing'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('discovery settings sheet closes when Done is tapped', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const HomeScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Done'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Discovery Settings'), findsNothing);
      expect(
        find.bySemanticsLabel('sheet:discovery-settings'),
        findsNothing,
      );
    });

    testWidgets('discover screen retains screen:discover semantics after sheet closes',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const HomeScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Open and close the filter sheet.
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Done'));
      // Pump multiple frames to let sheet fully dismiss
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // The main discover screen semantics label must still be present.
      final discoverySemantics = find.byWidgetPredicate(
        (w) => w is Semantics && (w as Semantics).properties.label == 'screen:discover',
      );
      expect(discoverySemantics, findsOneWidget);
    });
  });
}
