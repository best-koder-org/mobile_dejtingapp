import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/wizard/orientation_screen.dart';
import 'package:dejtingapp/models/onboarding_data.dart';
import '../../helpers/onboarding_test_helper.dart';

void main() {
  group('OrientationScreen', () {
    const route = '/onboarding/orientation';

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const OrientationScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows orientation options', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const OrientationScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Straight', skipOffstage: false), findsOneWidget);
      expect(find.text('Gay', skipOffstage: false), findsOneWidget);
      expect(find.text('Bisexual', skipOffstage: false), findsOneWidget);
    });

    testWidgets('selecting Straight stores in data and navigates',
        (tester) async {
      final data = OnboardingData();
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const OrientationScreen(),
        routeName: route,
        data: data,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Straight'));
      await tester.pumpAndSettle();

      // Tap Next (use l10n key fallback — find the ElevatedButton)
      final nextBtns = find.byType(ElevatedButton);
      await tester.tap(nextBtns.last);
      await tester.pumpAndSettle();

      expect(data.orientation, contains('Straight'));
      expect(find.text('match-preferences'), findsOneWidget);
    });

    testWidgets('has progress bar', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const OrientationScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('has "Show on profile" checkbox', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const OrientationScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('bottom buttons are protected from system navigation bar', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const OrientationScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is SafeArea && !w.top && w.bottom),
        findsOneWidget,
      );
    });

    testWidgets('has screen:onboarding-orientation semantics label', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const OrientationScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is Semantics && (w as Semantics).properties.label == 'screen:onboarding-orientation'),
        findsOneWidget,
      );
    });
  });
}