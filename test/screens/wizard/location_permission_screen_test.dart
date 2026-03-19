import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/wizard/location_permission_screen.dart';
import '../../helpers/onboarding_test_helper.dart';

void main() {
  group('Location Permission Screen', () {
    Widget buildSubject() {
      return buildOnboardingTestHarness(
        screen: const LocationPermissionScreen(),
        routeName: '/onboarding/location',
      );
    }

    testWidgets('renders Scaffold', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows progress bar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows location icon', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('shows header text from l10n', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: enableLocation = "Enable location"
      expect(find.text('Enable location'), findsOneWidget);
    });

    testWidgets('shows explanation text', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: locationDescription contains "nearby"
      expect(find.textContaining('nearby'), findsOneWidget);
    });

    testWidgets('shows Enable Location button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: enableLocationBtn = "Enable Location"
      expect(find.text('Enable Location'), findsOneWidget);
    });

    testWidgets('shows Not now skip button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: notNow = "Not now"
      expect(find.text('Not now'), findsOneWidget);
    });

    testWidgets('Not now button navigates to next screen', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(find.text('notifications'), findsOneWidget);
    });

    testWidgets('shows back button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('bottom buttons are protected from system navigation bar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byWidgetPredicate((w) => w is SafeArea && !w.top && w.bottom),
        findsOneWidget,
      );
    });

    testWidgets('has screen:onboarding-location semantics label', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const LocationPermissionScreen(),
        routeName: '/onboarding/location',
      ));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('screen:onboarding-location'),
        findsOneWidget,
      );
    });
  });
}