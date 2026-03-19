import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/settings_screen.dart';
import 'package:dejtingapp/screens/verification_selfie_screen.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('SettingsScreen', () {
    testWidgets('renders scaffold with app bar', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows Settings title', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('shows Account section header', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Account'), findsOneWidget);
    });

    testWidgets('shows Edit Profile option', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Edit profile'), findsOneWidget);
    });

    testWidgets('shows distance slider', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsAtLeastNWidgets(1));
    });

    testWidgets('shows age range slider', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RangeSlider), findsOneWidget);
    });

    testWidgets('shows ListView for scrollable content', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows language option', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('LANGUAGES'), findsOneWidget);
    });

    testWidgets('shows logout button', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('about dialog shows localized version and description strings',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();
      expect(find.text('Version: 1.0.0'), findsOneWidget);
      expect(
        find.text('Find your perfect match with our AI-powered dating app.'),
        findsOneWidget,
      );
      expect(
        find.text('Made with ❤️ by the DatingApp Team'),
        findsOneWidget,
      );
    });

    testWidgets('tapping Verification navigates to VerificationSelfieScreen',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verify Your Account'));
      await tester.pumpAndSettle();
      expect(find.byType(VerificationSelfieScreen), findsOneWidget);
    });

    testWidgets('shows Rate Us tile with star icon', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Rate Us'), 100);
      expect(find.text('Rate Us'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('tapping Rate Us tile triggers _rateApp and shows snackbar fallback',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Rate Us'), 100);
      await tester.tap(find.text('Rate Us'));
      // Allow async _rateApp to complete (url_launcher fails in test env)
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      // In test environment url_launcher cannot open the store, so the
      // snackbar fallback message should be shown.
      expect(
        find.text('Could not open the store page. Please try again later.'),
        findsOneWidget,
      );
    });
  });
}
