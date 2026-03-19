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
      await tester.pumpAndSettle();

      // The Semantics label used by visual-qa signatures for discover_explore.
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
      await tester.pumpAndSettle();

      // Title, sliders, visibility toggle, and done button must all be present.
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
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // The main discover screen semantics label must still be present.
      expect(find.bySemanticsLabel('screen:discover'), findsOneWidget);
    });
  });
}
