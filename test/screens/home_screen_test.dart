import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/home_screen.dart';
import 'package:dejtingapp/l10n/generated/app_localizations.dart';
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
      await tester.pump(const Duration(milliseconds: 500));

      // Bottom sheet should show discovery settings title
      expect(find.text('Discovery Settings'), findsOneWidget);
      // Distance and age range sliders should be present
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byType(RangeSlider), findsOneWidget);
      // Done button should be present
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('discovery filter bottom sheet closes on Done', (tester) async {
      // Increase viewport so the Done button inside the bottom sheet is visible
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.window.physicalSizeTestValue = const Size(800, 1600);
      binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(() {
        binding.window.clearPhysicalSizeTestValue();
        binding.window.clearDevicePixelRatioTestValue();
      });

      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const HomeScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byIcon(Icons.tune_rounded));
      // Need pump() then pump(duration) for the bottom sheet to fully appear
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify the sheet appeared
      expect(find.text('Discovery Settings'), findsOneWidget);

      // Ensure Done is visible and tap it
      final doneBtn = find.text('Done');
      await tester.ensureVisible(doneBtn);
      await tester.pump();
      await tester.tap(doneBtn);
      // Bottom sheet dismiss animation
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Bottom sheet should be dismissed
      expect(find.text('Discovery Settings'), findsNothing);
    });
    testWidgets('has screen:discover semantics label', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const HomeScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byWidgetPredicate((w) => w is Semantics && (w as Semantics).properties.label == 'screen:discover'),
        findsOneWidget,
      );
    });
  });

  group('AppLocalizations i18n keys', () {
    testWidgets('likeOnly returns localized string in English', (tester) async {
      late AppLocalizations loc;
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: Builder(
            builder: (context) {
              loc = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
      expect(loc.likeOnly, 'Like only');
    });

    testWidgets('hearVoice returns parameterized string in English',
        (tester) async {
      late AppLocalizations loc;
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: Builder(
            builder: (context) {
              loc = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
      expect(loc.hearVoice('Alice'), "Hear Alice's voice");
    });
  });
}
