import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/wizard/age_range_screen.dart';
import 'package:dejtingapp/models/onboarding_data.dart';
import '../../helpers/onboarding_test_helper.dart';

void main() {
  group('AgeRangeScreen', () {
    const route = '/onboarding/age-range';

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const AgeRangeScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows RangeSlider', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const AgeRangeScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(RangeSlider), findsOneWidget);
    });

    testWidgets('Next button always enabled', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const AgeRangeScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('tapping Next navigates to relationship-goals', (tester) async {
      final data = OnboardingData();
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const AgeRangeScreen(),
        routeName: route,
        data: data,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();

      expect(find.text('relationship-goals'), findsOneWidget);
    });

    testWidgets('has progress bar', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const AgeRangeScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('initializes from existing data', (tester) async {
      final data = OnboardingData()
        ..minAge = 25
        ..maxAge = 40;
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const AgeRangeScreen(),
        routeName: route,
        data: data,
      ));
      await tester.pumpAndSettle();

      // The age display should show the initialized range
      expect(find.textContaining('25'), findsWidgets);
      expect(find.textContaining('40'), findsWidgets);
    });

    testWidgets('bottom buttons are protected from system navigation bar', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const AgeRangeScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is SafeArea && !w.top && w.bottom),
        findsOneWidget,
      );
    });

    testWidgets('has screen:onboarding-age-range semantics label', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const AgeRangeScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is Semantics && (w as Semantics).properties.label == 'screen:onboarding-age-range'),
        findsOneWidget,
      );
    });
  });
}