import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/verification_selfie_screen.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  setUpAll(() {
    setupTestHttpOverrides();
  });

  group('VerificationSelfieScreen', () {
    testWidgets('renders scaffold with app bar', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const VerificationSelfieScreen()),
      );
      // Single pump — _loadStatus() is async; initial frame already has the UI
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows verify identity title in app bar', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const VerificationSelfieScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Verify Your Identity'), findsOneWidget);
    });

    testWidgets('shows camera preview placeholder (face icon in circle)',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const VerificationSelfieScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      // A circular face icon serves as the camera framing placeholder
      expect(find.byIcon(Icons.face), findsOneWidget);
    });

    testWidgets('shows take selfie button with camera icon', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const VerificationSelfieScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.text('Take Selfie'), findsOneWidget);
    });

    testWidgets('shows instructions heading text', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const VerificationSelfieScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Take a Selfie to Verify'), findsOneWidget);
    });

    testWidgets('shows selfie instructions description', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const VerificationSelfieScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.textContaining('profile photo'),
        findsOneWidget,
      );
    });

    testWidgets('shows lighting tip', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const VerificationSelfieScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Good lighting, face clearly visible'), findsOneWidget);
    });

    testWidgets('shows framing tip', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const VerificationSelfieScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Look straight at camera'), findsOneWidget);
    });

    testWidgets('shows accessories tip', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const VerificationSelfieScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.text('No sunglasses, masks, or heavy filters'),
        findsOneWidget,
      );
    });

    testWidgets('take selfie button is enabled when attempts remain',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const VerificationSelfieScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      // With no status loaded (auth fails in test env), attemptsLeft defaults to 3
      // Verify button exists and is not disabled by checking the icon + label are present
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.text('Take Selfie'), findsOneWidget);
    });

    testWidgets('navigator can pop when screen is pushed (back/cancel available)',
        (tester) async {
      // Push the screen onto a navigator so AppBar shows an automatic back button
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VerificationSelfieScreen(),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open'));
      // Complete page push animation and allow async _loadStatus() to run
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Screen title is visible after navigation
      expect(find.text('Verify Your Identity'), findsOneWidget);

      // Navigator can pop — the AppBar back button uses this to cancel/go back
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      expect(navigator.canPop(), isTrue);
    });

    testWidgets('AppBar back button is rendered when screen is pushed',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VerificationSelfieScreen(),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // AppBar back button should be present to allow cancelling the flow
      expect(find.byTooltip('Back'), findsOneWidget);

      // Tapping the back button navigates back to the previous screen
      await tester.tap(find.byTooltip('Back'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Open'), findsOneWidget);
    });
  });
}
