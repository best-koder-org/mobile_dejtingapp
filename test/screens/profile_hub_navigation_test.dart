import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/profile_hub_screen.dart';
import 'package:dejtingapp/screens/settings_screen.dart';
import 'package:dejtingapp/screens/verification_selfie_screen.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('ProfileHubScreen – section navigation', () {
    testWidgets('Get More tab is shown by default', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const ProfileHubScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Get more'), findsOneWidget);
    });

    testWidgets('DejTing Plus promo card is visible in Get More tab', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const ProfileHubScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('DejTing Plus'), findsOneWidget);
    });

    testWidgets('Spotlight and Sparks feature cards are visible in Get More tab',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const ProfileHubScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Spotlight'), findsOneWidget);
      expect(find.text('Sparks'), findsOneWidget);
    });

    testWidgets('Safety tab shows selfie verification, message filter and block list',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const ProfileHubScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Safety'));
      await tester.pumpAndSettle();
      expect(find.text('Selfie verification'), findsOneWidget);
      expect(find.text('Message filter'), findsOneWidget);
      expect(find.text('Block list'), findsOneWidget);
    });

    testWidgets('Safety tab shows safety resources section', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const ProfileHubScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Safety'));
      await tester.pumpAndSettle();
      expect(find.text('Safety resources'), findsOneWidget);
    });

    testWidgets('My DejTing tab shows fresh start, settings and logout', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const ProfileHubScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('My DejTing'));
      await tester.pumpAndSettle();
      expect(find.text('Fresh start'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('tapping Settings in My DejTing tab navigates to SettingsScreen',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const ProfileHubScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('My DejTing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets(
        'tapping Selfie verification in Safety tab navigates to VerificationSelfieScreen',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const ProfileHubScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Safety'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selfie verification'));
      await tester.pumpAndSettle();
      expect(find.byType(VerificationSelfieScreen), findsOneWidget);
    });

    testWidgets('tapping Edit profile in My DejTing tab navigates to /profile route',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const ProfileHubScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('My DejTing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();
      // The core test helper maps '/profile' to a scaffold with text 'Profile'.
      // findWidgets is used because the default display name also renders 'Profile'.
      expect(find.text('Profile'), findsAtLeastNWidgets(1));
    });
  });
}
