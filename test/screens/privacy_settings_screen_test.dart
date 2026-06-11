import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/privacy_settings_screen.dart';
import 'package:dejtingapp/screens/settings_screen.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('PrivacySettingsScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const PrivacySettingsScreen()),
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows correct title', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const PrivacySettingsScreen()),
      );
      await tester.pump();
      expect(find.text('Privacy Settings'), findsOneWidget);
    });

    testWidgets('shows privacy controls', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const PrivacySettingsScreen()),
      );
      // First frame shows loading state + static controls
      expect(find.text('Show me in discovery'), findsOneWidget);
      expect(find.text('Blocked users'), findsOneWidget);
      // The loading indicator is shown while getBlockedUsers() runs
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('tapping Privacy in SettingsScreen navigates to it',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Scroll to find 'Privacy & Security' (same pattern as help_screen_test)
      final scrollable = find.byType(Scrollable).first;
      bool found = false;
      for (int i = 0; i < 10; i++) {
        if (tester.any(find.text('Privacy & Security'))) {
          found = true;
          break;
        }
        await tester.drag(scrollable, const Offset(0, -200));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(found, isTrue,
          reason: 'Could not find Privacy & Security after scrolling');

      await tester.tap(find.text('Privacy & Security'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PrivacySettingsScreen), findsOneWidget);
    });
  });
}
