import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/wizard/onboarding_complete_screen.dart';
import '../../helpers/onboarding_test_helper.dart';

void main() {
  group('Onboarding Complete Screen', () {
    Widget buildSubject() {
      return buildOnboardingTestHarness(
        screen: const OnboardingCompleteScreen(),
        routeName: '/onboarding/complete',
      );
    }

    testWidgets('renders Scaffold', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows progress bar at full', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, 1.0);
    });

    testWidgets('shows screen state after init', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 2));
      // Screen will be in submitting, error, or success state
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('error state shows something went wrong text', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 2));
      // l10n: somethingWentWrong = "Something went wrong"
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('error state shows retry button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 2));
      // l10n: tryAgainButton = "Try Again" (capital A)
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('error state shows skip for now option', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 2));
      // l10n: skipForNow = "Skip for now"
      expect(find.text('Skip for now'), findsOneWidget);
    });

    testWidgets('has screen:onboarding-complete semantics label', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const OnboardingCompleteScreen(),
        routeName: '/onboarding/complete',
      ));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is Semantics && (w as Semantics).properties.label == 'screen:onboarding-complete'),
        findsOneWidget,
      );
    });
  });
}