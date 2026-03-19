import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/wizard/match_preferences_screen.dart';
import 'package:dejtingapp/models/onboarding_data.dart';
import '../../helpers/onboarding_test_helper.dart';

void main() {
  group('MatchPreferencesScreen', () {
    const route = '/onboarding/match-preferences';

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const MatchPreferencesScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows Men, Women, Everyone buttons', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const MatchPreferencesScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Men'), findsOneWidget);
      expect(find.text('Women'), findsOneWidget);
      expect(find.text('Everyone'), findsOneWidget);
    });

    testWidgets('Next button disabled initially', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const MatchPreferencesScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('selecting Everyone enables Next', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const MatchPreferencesScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Everyone'));
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('tapping Next stores preference and navigates', (tester) async {
      final data = OnboardingData();
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const MatchPreferencesScreen(),
        routeName: route,
        data: data,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Women'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();

      expect(data.preferredGender, 'Women');
      expect(find.text('age-range'), findsOneWidget);
    });

    testWidgets('has progress bar', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const MatchPreferencesScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('bottom buttons are protected from system navigation bar', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const MatchPreferencesScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is SafeArea && !w.top && w.bottom),
        findsOneWidget,
      );
    });

    testWidgets('has screen:onboarding-match-preferences semantics label', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const MatchPreferencesScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('screen:onboarding-match-preferences'),
        findsOneWidget,
      );
    });
  });
}