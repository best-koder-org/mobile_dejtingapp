import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/settings_screen.dart';
import 'package:dejtingapp/screens/help_screen.dart';
import 'package:dejtingapp/screens/location_settings_screen.dart';
import 'package:dejtingapp/screens/privacy_settings_screen.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('SettingsScreen – all tiles render', () {
    testWidgets('Account section header is visible', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Account'), findsOneWidget);
    });

    testWidgets('Account section: Edit profile tile renders', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Edit profile'), findsOneWidget);
    });

    testWidgets('Account section: Verify Your Account tile renders', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Verify Your Account'), findsOneWidget);
    });

    testWidgets('Account section: Privacy & Security tile renders', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Privacy & Security'), findsOneWidget);
    });

    testWidgets('Account section: Languages tile renders', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('LANGUAGES'), findsOneWidget);
    });

    testWidgets('Discovery section header is visible', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Discovery Settings'), findsOneWidget);
    });

    testWidgets('Discovery section: Location tile renders', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Location'), findsOneWidget);
    });

    testWidgets('Discovery section: Show me on DejTing toggle renders', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Show me on DejTing'), 100);
      expect(find.text('Show me on DejTing'), findsOneWidget);
    });

    testWidgets('Notifications section header is visible', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Notifications'), 100);
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('Notifications section: Push Notifications toggle renders', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Push Notifications'), 100);
      expect(find.text('Push Notifications'), findsOneWidget);
    });

    testWidgets('Profile Display section header is visible', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Profile Display'), 100);
      expect(find.text('Profile Display'), findsOneWidget);
    });

    testWidgets('Profile Display section: Show Age toggle renders', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Show Age'), 100);
      expect(find.text('Show Age'), findsOneWidget);
    });

    testWidgets('Profile Display section: Show Distance toggle renders', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Show Distance'), 100);
      expect(find.text('Show Distance'), findsOneWidget);
    });

    testWidgets('Support & About section header is visible after scroll', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Support & About'), 100);
      expect(find.text('Support & About'), findsOneWidget);
    });

    testWidgets('Support & About: Help & Support tile renders after scroll', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Help & Support'), 100);
      expect(find.text('Help & Support'), findsOneWidget);
    });

    testWidgets('Support & About: About tile renders after scroll', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('About'), 100);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('Support & About: Rate Us tile renders after scroll', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Rate Us'), 100);
      expect(find.text('Rate Us'), findsOneWidget);
    });

    testWidgets('Logout button renders after scroll', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Logout'), 100);
      expect(find.text('Logout'), findsOneWidget);
    });
  });

  group('SettingsScreen – tile navigation', () {
    testWidgets('tapping Privacy & Security navigates to PrivacySettingsScreen',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Privacy & Security'));
      await tester.pumpAndSettle();
      expect(find.byType(PrivacySettingsScreen), findsOneWidget);
    });

    testWidgets('tapping Location navigates to LocationSettingsScreen', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();
      expect(find.byType(LocationSettingsScreen), findsOneWidget);
    });

    testWidgets('tapping Help & Support navigates to HelpScreen', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Help & Support'), 100);
      await tester.tap(find.text('Help & Support'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpScreen), findsOneWidget);
    });

    testWidgets('tapping Edit profile navigates to /profile route', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();
      // The core test helper maps '/profile' to a scaffold with text 'Profile'
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Show me on DejTing toggle is tappable', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Show me on DejTing'), 100);
      final toggle = find.widgetWithText(SwitchListTile, 'Show me on DejTing');
      expect(toggle, findsOneWidget);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
    });

    testWidgets('Push Notifications toggle is tappable', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Push Notifications'), 100);
      final toggle = find.widgetWithText(SwitchListTile, 'Push Notifications');
      expect(toggle, findsOneWidget);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
    });
  });
}
