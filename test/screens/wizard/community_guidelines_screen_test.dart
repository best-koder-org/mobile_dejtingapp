import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/wizard/community_guidelines_screen.dart';
import '../../helpers/onboarding_test_helper.dart';

void main() {
  group('Community Guidelines Screen', () {
    Widget buildSubject() {
      return buildOnboardingTestHarness(
        screen: const CommunityGuidelinesScreen(),
        routeName: '/onboarding/community-guidelines',
      );
    }

    testWidgets('renders welcome title', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: welcomeToDejTing = "Welcome to DejTing."
      expect(find.text('Welcome to DejTing.'), findsOneWidget);
    });

    testWidgets('shows house rules subtitle', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: followHouseRules = "Please follow these House Rules."
      expect(find.textContaining('House Rules'), findsOneWidget);
    });

    testWidgets('shows Be yourself rule', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Be yourself'), findsOneWidget);
    });

    testWidgets('shows Stay safe rule', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Stay safe'), findsOneWidget);
    });

    testWidgets('shows Play it cool rule', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Play it cool'), findsOneWidget);
    });

    testWidgets('shows Be proactive rule', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Be proactive'), findsOneWidget);
    });

    testWidgets('has I agree button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: iAgreeButton = "I agree"
      expect(find.text('I agree'), findsOneWidget);
    });

    testWidgets('I agree navigates to next screen', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('I agree'));
      await tester.pumpAndSettle();
      // Should navigate to first-name screen
      expect(find.text('first-name'), findsOneWidget);
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

    testWidgets('has green checkmark icons for rules', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.check), findsNWidgets(4));
    });

    testWidgets('has screen:onboarding-community-guidelines semantics label', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const CommunityGuidelinesScreen(),
        routeName: '/onboarding/community-guidelines',
      ));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is Semantics && (w as Semantics).properties.label == 'screen:onboarding-community-guidelines'),
        findsOneWidget,
      );
    });
  });
}