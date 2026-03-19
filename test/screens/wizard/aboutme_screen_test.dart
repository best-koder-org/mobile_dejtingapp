import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/wizard/aboutme_screen.dart';
import '../../helpers/onboarding_test_helper.dart';

void main() {
  group('About Me Screen', () {
    Widget buildSubject() {
      return buildOnboardingTestHarness(
        screen: const AboutMeScreen(),
        routeName: '/onboarding/about-me',
      );
    }

    testWidgets('renders header from l10n', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: whatMakesYouYou = "What else makes\nyou, you?"
      expect(find.textContaining('makes'), findsOneWidget);
    });

    testWidgets('shows authenticity subtitle', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: authenticitySubtitle contains "Authenticity"
      expect(find.textContaining('Authenticity'), findsOneWidget);
    });

    testWidgets('shows communication style section', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: aboutMeCommunicationStyle = "Communication style"
      expect(find.text('Communication style'), findsOneWidget);
      expect(find.text('Big time texter'), findsOneWidget);
      expect(find.text('Better in person'), findsOneWidget);
    });

    testWidgets('shows love language section', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: aboutMeLoveLanguage = "Love language"
      expect(find.text('Love language'), findsOneWidget);
      expect(find.text('Thoughtful gestures'), findsOneWidget);
      expect(find.text('Time together'), findsOneWidget);
    });

    testWidgets('shows education section', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: aboutMeEducationLevel = "Education level"
      expect(find.text('Education level'), findsOneWidget);
      expect(find.text("Bachelor's degree"), findsOneWidget);
    });

    testWidgets('has Skip button in app bar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: skipButton = "Skip"
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('bottom button shows Skip & finish initially', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: skipAndFinish = "Skip & finish"
      expect(find.text('Skip & finish'), findsOneWidget);
    });

    testWidgets('selecting option changes button text', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Big time texter'));
      await tester.pump();
      // l10n: letsGo = "Let's go! 🎉"
      expect(find.textContaining("Let's go"), findsOneWidget);
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

    testWidgets('has screen:onboarding-about-me semantics label', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const AboutMeScreen(),
        routeName: '/onboarding/about-me',
      ));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('screen:onboarding-about-me'),
        findsOneWidget,
      );
    });
  });
}