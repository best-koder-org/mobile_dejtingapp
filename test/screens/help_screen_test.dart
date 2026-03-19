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
      await tester.pump(const Duration(milliseconds: 500));

      // Scroll to find 'Help & Support' using manual pump-and-drag
      // (scrollUntilVisible uses pumpAndSettle which may timeout)
      final scrollable = find.byType(Scrollable).first;
      bool found = false;
      for (int i = 0; i < 10; i++) {
        if (tester.any(find.text('Help & Support'))) {
          found = true;
          break;
        }
        await tester.drag(scrollable, const Offset(0, -200));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(found, isTrue, reason: 'Could not find Help & Support after scrolling');

      await tester.tap(find.text('Help & Support'));
      // Pump through the navigation transition
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(HelpScreen), findsOneWidget);
    });
  });
}
