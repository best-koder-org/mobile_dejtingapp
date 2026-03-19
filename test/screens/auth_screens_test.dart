import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/auth_screens.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const LoginScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows app logo icon and title', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const LoginScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.text('DejTing'), findsOneWidget);
    });

    testWidgets('shows tagline', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const LoginScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Find your perfect match'), findsOneWidget);
    });

    testWidgets('primary sign-in button (Continue with Phone Number) is present',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const LoginScreen(),
          extraRoutes: {
            '/onboarding/phone-entry': (_) =>
                const Scaffold(body: Text('phone-entry')),
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continue with Phone Number'), findsOneWidget);
    });

    testWidgets(
        'tapping Continue with Phone Number navigates to phone-entry',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const LoginScreen(),
          extraRoutes: {
            '/onboarding/phone-entry': (_) =>
                const Scaffold(body: Text('phone-entry')),
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue with Phone Number'));
      await tester.pumpAndSettle();
      expect(find.text('phone-entry'), findsOneWidget);
    });

    testWidgets('Sign in with Browser button is present', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const LoginScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sign in with Browser'), findsOneWidget);
    });

    testWidgets('no email or password text fields (phone-first design)',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const LoginScreen()),
      );
      await tester.pumpAndSettle();
      // Screen is phone/passwordless — no text input fields should be present
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('no forgot-password link (passwordless design)', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const LoginScreen()),
      );
      await tester.pumpAndSettle();
      final hasForgotPassword =
          find.textContaining('Forgot').evaluate().isNotEmpty ||
              find.textContaining('forgot').evaluate().isNotEmpty ||
              find.textContaining('Reset').evaluate().isNotEmpty;
      expect(hasForgotPassword, isFalse);
    });
  });

  group('RegisterScreen', () {
    testWidgets('renders and shows loading indicator while redirecting',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const RegisterScreen(),
          extraRoutes: {
            '/onboarding/phone-entry': (_) =>
                const Scaffold(body: Text('phone-entry')),
          },
        ),
      );
      // Initial frame shows the loading spinner
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('redirects to phone-entry screen', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const RegisterScreen(),
          extraRoutes: {
            '/onboarding/phone-entry': (_) =>
                const Scaffold(body: Text('phone-entry')),
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('phone-entry'), findsOneWidget);
    });
  });
}
