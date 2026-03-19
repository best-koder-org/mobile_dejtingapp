import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/wizard/first_name_screen.dart';
import 'package:dejtingapp/models/onboarding_data.dart';
import '../../helpers/onboarding_test_helper.dart';

void main() {
  group('FirstNameScreen', () {
    const route = '/onboarding/first-name';

    testWidgets('renders without layout errors (catches infinite width crash)',
        (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const FirstNameScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows header text', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const FirstNameScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('first name'), findsOneWidget);
    });

    testWidgets('has a text field', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const FirstNameScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Next button disabled when empty', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const FirstNameScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      // find.byType(ElevatedButton) should find the Next button
      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('Next button enabled with valid name', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const FirstNameScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Alice');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Next button stays disabled with single char', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const FirstNameScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'A');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('tapping Next stores name and navigates to birthday',
        (tester) async {
      final data = OnboardingData();
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const FirstNameScreen(),
        routeName: route,
        data: data,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Alice');
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(data.firstName, 'Alice');
      expect(find.text('birthday'), findsOneWidget);
    });

    testWidgets('has progress bar', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const FirstNameScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('has back and close navigation', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const FirstNameScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows visibility info', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const FirstNameScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.textContaining('visible'), findsOneWidget);
    });

    testWidgets('accepts accented and hyphenated names', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const FirstNameScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), "Marie-Ève");
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('bottom buttons are protected from system navigation bar', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const FirstNameScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is SafeArea && !w.top && w.bottom),
        findsOneWidget,
      );
    });
  });
}
