import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/wizard/interests_screen.dart';
import '../../helpers/onboarding_test_helper.dart';

void main() {
  group('Interests Screen', () {
    Widget buildSubject() {
      return buildOnboardingTestHarness(
        screen: const InterestsScreen(),
        routeName: '/onboarding/interests',
      );
    }

    testWidgets('renders header from l10n', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: whatAreYouInto = "What are you into?"
      expect(find.text('What are you into?'), findsOneWidget);
    });

    testWidgets('shows max interests instruction', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: addUpToInterests = "Add up to {max} interests..."
      expect(find.textContaining('10 interests'), findsOneWidget);
    });

    testWidgets('shows selection counter', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: interestsSelectedCount = "{count} / {max} selected"
      expect(find.text('0 / 10 selected'), findsOneWidget);
    });

    testWidgets('shows category headers with emojis', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: interestCategoryOutdoors = "Outdoors & adventure"
      expect(find.textContaining('Outdoors'), findsOneWidget);
      // l10n: interestCategoryMusic = "Music"
      expect(find.textContaining('Music'), findsOneWidget);
    });

    testWidgets('has Skip button in app bar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('shows Skip for now button at bottom initially', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: skipForNow = "Skip for now"
      expect(find.text('Skip for now'), findsOneWidget);
    });

    testWidgets('tapping interest updates counter', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Hiking'));
      await tester.pump();
      expect(find.text('1 / 10 selected'), findsOneWidget);
    });

    testWidgets('selecting interest changes button to Continue', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Hiking'));
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

    testWidgets('has screen:onboarding-interests semantics label', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const InterestsScreen(),
        routeName: '/onboarding/interests',
      ));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is Semantics && (w as Semantics).properties.label == 'screen:onboarding-interests'),
        findsOneWidget,
      );
    });
  });
}