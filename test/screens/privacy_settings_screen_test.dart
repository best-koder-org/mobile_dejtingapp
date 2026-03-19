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
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows correct title', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const PrivacySettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Privacy Settings'), findsOneWidget);
    });

    testWidgets('shows placeholder body text', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const PrivacySettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Privacy settings coming soon'), findsOneWidget);
    });

    testWidgets('tapping Privacy in SettingsScreen navigates to it',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Privacy & Security'));
      await tester.pumpAndSettle();
      expect(find.byType(PrivacySettingsScreen), findsOneWidget);
    });
  });
}
