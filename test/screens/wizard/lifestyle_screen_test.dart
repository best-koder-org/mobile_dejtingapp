import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/wizard/lifestyle_screen.dart';
import '../../helpers/onboarding_test_helper.dart';

void main() {
  group('Lifestyle Screen', () {
    Widget buildSubject() {
      return buildOnboardingTestHarness(
        screen: const LifestyleScreen(),
        routeName: '/onboarding/lifestyle',
      );
    }

    testWidgets('renders header from l10n', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: lifestyleHabits = "Lifestyle habits"
      expect(find.text('Lifestyle habits'), findsOneWidget);
    });

    testWidgets('shows optional info subtitle', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: lifestyleSubtitle contains "optional"
      expect(find.textContaining('optional'), findsOneWidget);
    });

    testWidgets('shows smoking section', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: lifestyleSmokingTitle = "How often do you smoke?"
      expect(find.text('How often do you smoke?'), findsOneWidget);
      expect(find.text('Non-smoker'), findsOneWidget);
      expect(find.text('Social smoker'), findsOneWidget);
    });

    testWidgets('shows exercise section', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: lifestyleExerciseTitle = "Do you exercise?"
      expect(find.textContaining('exercise'), findsOneWidget);
      expect(find.text('Every day'), findsOneWidget);
      expect(find.text('Often'), findsOneWidget);
    });

    testWidgets('shows pets section', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Dog'), findsOneWidget);
      expect(find.text('Cat'), findsOneWidget);
    });

    testWidgets('has Skip button in app bar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('bottom button shows Skip for now initially', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: skipForNow = "Skip for now"
      expect(find.text('Skip for now'), findsOneWidget);
    });

    testWidgets('selecting option changes button to Continue', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Non-smoker'));
      await tester.pump();
      // l10n: continueButton = "Continue"
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('has progress bar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('has back navigation', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('has screen:onboarding-lifestyle semantics label', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const LifestyleScreen(),
        routeName: '/onboarding/lifestyle',
      ));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('screen:onboarding-lifestyle'),
        findsOneWidget,
      );
    });
  });
}