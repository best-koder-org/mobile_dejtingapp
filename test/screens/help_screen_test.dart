import 'package:dejtingapp/screens/help_screen.dart';
import 'package:dejtingapp/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('HelpScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildCoreScreenTestApp(home: const HelpScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows correct title', (tester) async {
      await tester.pumpWidget(buildCoreScreenTestApp(home: const HelpScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Help & Support'), findsOneWidget);
    });

    testWidgets('tapping Help in SettingsScreen navigates to HelpScreen',
        (tester) async {
      await tester
          .pumpWidget(buildCoreScreenTestApp(home: const SettingsScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Help & Support'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpScreen), findsOneWidget);
    });
  });
}
