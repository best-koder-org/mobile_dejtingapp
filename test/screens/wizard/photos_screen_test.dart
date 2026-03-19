import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/wizard/photos_screen.dart';
import '../../helpers/onboarding_test_helper.dart';

void main() {
  group('Photos Screen', () {
    Widget buildSubject() {
      return buildOnboardingTestHarness(
        screen: const PhotosScreen(),
        routeName: '/onboarding/photos',
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

    testWidgets('shows Add photos header', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: addPhotos = "Add photos"
      expect(find.text('Add photos'), findsOneWidget);
    });

    testWidgets('shows photos subtitle with at least 2', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: photosSubtitle contains "at least 2"
      expect(find.textContaining('at least 2'), findsOneWidget);
    });

    testWidgets('shows photo grid with slots', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(GridView), findsOneWidget);
      // Not all 6 slots may be visible due to viewport constraints
      // but at least the first row (3 slots) should be visible
      expect(find.byIcon(Icons.add), findsAtLeastNWidgets(3));
    });

    testWidgets('shows status text with photo count', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // Status text shows "0/6 photos" with count of needing 2 more
      expect(find.textContaining('0/6'), findsOneWidget);
    });

    testWidgets('Continue button is disabled with no photos', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: continueButton = "Continue"
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continue'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('has back arrow button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('has close button in app bar', (tester) async {
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

    testWidgets('has screen:onboarding-photos semantics label', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const PhotosScreen(),
        routeName: '/onboarding/photos',
      ));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('screen:onboarding-photos'),
        findsOneWidget,
      );
    });
  });
}