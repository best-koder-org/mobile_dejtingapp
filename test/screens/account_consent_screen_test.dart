import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/l10n/generated/app_localizations.dart';
import 'package:dejtingapp/screens/account_consent_screen.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('AccountConsentScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const AccountConsentScreen(authProvider: 'google'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows title from AppLocalizations', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const AccountConsentScreen(authProvider: 'google'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Choose an account'), findsOneWidget);
    });

    testWidgets('shows subtitle with provider name', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const AccountConsentScreen(authProvider: 'google'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Log in with Google'), findsOneWidget);
    });

    testWidgets('shows "Use another account" button', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const AccountConsentScreen(authProvider: 'google'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Use another account'), findsOneWidget);
    });

    testWidgets('shows continue button', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const AccountConsentScreen(authProvider: 'google'),
          extraRoutes: {
            '/onboarding/phone-entry': (_) =>
                const Scaffold(body: Text('phone-entry')),
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('shows legal/privacy text', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const AccountConsentScreen(authProvider: 'google'),
        ),
      );
      await tester.pumpAndSettle();
      // RichText spans aren't found by find.textContaining; search semantics instead
      expect(
        find.byWidgetPredicate((w) =>
          w is RichText && w.text.toPlainText().contains('privacy policy')),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) =>
          w is RichText && w.text.toPlainText().contains('terms of use')),
        findsOneWidget,
      );
    });

    testWidgets('shows footer links', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const AccountConsentScreen(authProvider: 'google'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Help'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('Terms'), findsOneWidget);
    });

    testWidgets('shows user name and email when provided', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const AccountConsentScreen(
            authProvider: 'google',
            userName: 'Jane Doe',
            userEmail: 'jane@example.com',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('jane@example.com'), findsOneWidget);
    });

    testWidgets('renders in Swedish locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('sv'),
          home: const AccountConsentScreen(authProvider: 'google'),
          routes: {
            '/onboarding/phone-entry': (_) =>
                const Scaffold(body: Text('phone-entry')),
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Välj ett konto'), findsOneWidget);
      expect(find.text('Logga in med Google'), findsOneWidget);
      expect(find.text('Fortsätt'), findsOneWidget);
    });
  });
}
