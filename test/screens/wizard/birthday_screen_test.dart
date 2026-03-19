import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/wizard/birthday_screen.dart';
import '../../helpers/onboarding_test_helper.dart';

void main() {
  group('Birthday Screen', () {
    Widget buildSubject() {
      return buildOnboardingTestHarness(
        screen: const BirthdayScreen(),
        routeName: '/onboarding/birthday',
      );
    }

    testWidgets('renders birthday title from l10n', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n key: yourBirthday = "Your birthday?"
      expect(find.text('Your birthday?'), findsOneWidget);
    });

    testWidgets('shows birthday explainer text', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('age, not your date of birth'), findsOneWidget);
    });

    testWidgets('shows DD, MM, YYYY dropdown hints', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('DD'), findsOneWidget);
      expect(find.text('MM'), findsOneWidget);
      expect(find.text('YYYY'), findsOneWidget);
    });

    testWidgets('has three DropdownButtonFormField widgets', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(DropdownButtonFormField<int>), findsNWidgets(3));
    });

    testWidgets('has Next button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n key: nextButton = "Next"
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Next button is disabled when no date selected', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
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

    testWidgets('has close/abort button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('bottom buttons are protected from system navigation bar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byWidgetPredicate((w) => w is SafeArea && !w.top && w.bottom),
        findsOneWidget,
      );
    });
  });
}
