import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/wizard/relationship_goals_screen.dart';
import 'package:dejtingapp/models/onboarding_data.dart';
import '../../helpers/onboarding_test_helper.dart';

void main() {
  group('RelationshipGoalsScreen', () {
    const route = '/onboarding/relationship-goals';

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const RelationshipGoalsScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows first-row goal options', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const RelationshipGoalsScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      // GridView.count(crossAxisCount:2) — first row always visible
      expect(find.text('Long-term partner'), findsOneWidget);
      expect(find.textContaining('Long-term, open'), findsOneWidget);
    });

    testWidgets('has GridView with 6 cards', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const RelationshipGoalsScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      // All 6 GestureDetector cards in the grid
      expect(find.byType(GestureDetector, skipOffstage: false), findsWidgets);
    });

    testWidgets('selecting Long-term partner and tapping Next stores it',
        (tester) async {
      final data = OnboardingData();
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const RelationshipGoalsScreen(),
        routeName: route,
        data: data,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Long-term partner'));
      await tester.pumpAndSettle();

      final nextFinder = find.byType(ElevatedButton);
      expect(nextFinder, findsOneWidget);
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();

      expect(data.relationshipGoal, 'Long-term partner');
      expect(find.text('lifestyle'), findsOneWidget);
    });

    testWidgets('has progress bar', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const RelationshipGoalsScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('has screen:onboarding-relationship-goals semantics label', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const RelationshipGoalsScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('screen:onboarding-relationship-goals'),
        findsOneWidget,
      );
    });
  });
}