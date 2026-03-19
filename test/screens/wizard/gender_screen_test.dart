import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/wizard/gender_screen.dart';
import 'package:dejtingapp/models/onboarding_data.dart';
import '../../helpers/onboarding_test_helper.dart';

void main() {
  group('GenderScreen', () {
    const route = '/onboarding/gender';

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const GenderScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows Man and Woman quick-pick buttons', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const GenderScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Man'), findsOneWidget);
      expect(find.text('Woman'), findsOneWidget);
    });

    testWidgets('Next button disabled initially', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const GenderScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      final nextBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(nextBtn.onPressed, isNull);
    });

    testWidgets('selecting Man enables Next and stores in data', (tester) async {
      final data = OnboardingData();
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const GenderScreen(),
        routeName: route,
        data: data,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Man'));
      await tester.pump();

      final nextBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(nextBtn.onPressed, isNotNull);
    });

    testWidgets('tapping Next navigates to orientation', (tester) async {
      final data = OnboardingData();
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const GenderScreen(),
        routeName: route,
        data: data,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Woman'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();

      expect(data.gender, 'Woman');
      expect(find.text('orientation'), findsOneWidget);
    });

    testWidgets('has progress bar', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const GenderScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('has back and close icons', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const GenderScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('has "Show on profile" checkbox', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const GenderScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('bottom buttons are protected from system navigation bar', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const GenderScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is SafeArea && !w.top && w.bottom),
        findsOneWidget,
      );
    });

    testWidgets('has screen:onboarding-gender semantics label', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const GenderScreen(),
        routeName: route,
      ));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is Semantics && (w as Semantics).properties.label == 'screen:onboarding-gender'),
        findsOneWidget,
      );
    });
  });
}