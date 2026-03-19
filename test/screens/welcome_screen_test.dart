import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/welcome_screen.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('WelcomeScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const WelcomeScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows app name/logo', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const WelcomeScreen()),
      );
      await tester.pumpAndSettle();
      // Logo: flame icon
      final hasFireIcon =
          find.byIcon(Icons.local_fire_department).evaluate().isNotEmpty ||
              find.byIcon(Icons.whatshot).evaluate().isNotEmpty;
      expect(hasFireIcon, isTrue);
      // App name / headline text
      expect(find.text('Create account'), findsOneWidget);
    });

    testWidgets('shows signup/register button', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const WelcomeScreen(),
          extraRoutes: {
            '/onboarding/phone-entry': (_) =>
                const Scaffold(body: Text('phone-entry')),
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.ancestor(
          of: find.text("I'm ready to match"),
          matching: find.byType(ElevatedButton),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows login button', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const WelcomeScreen(),
          extraRoutes: {
            '/signin/phone-entry': (_) =>
                const Scaffold(body: Text('signin-phone-entry')),
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.ancestor(
          of: find.text('Sign in'),
          matching: find.byType(TextButton),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows terms or privacy text', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const WelcomeScreen()),
      );
      await tester.pumpAndSettle();
      final hasLegalText =
          find.textContaining('Terms').evaluate().isNotEmpty ||
              find.textContaining('Privacy').evaluate().isNotEmpty ||
              find.textContaining('terms').evaluate().isNotEmpty ||
              find.textContaining('privacy').evaluate().isNotEmpty;
      expect(hasLegalText, isTrue);
    });

    testWidgets('has screen:onboarding-welcome semantics label', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const WelcomeScreen()),
      );
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is Semantics && (w as Semantics).properties.label == 'screen:onboarding-welcome'),
        findsOneWidget,
      );
    });
  });
}
