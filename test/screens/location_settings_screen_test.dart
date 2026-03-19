import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/location_settings_screen.dart';
import 'package:dejtingapp/screens/settings_screen.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('LocationSettingsScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const LocationSettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows correct title', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const LocationSettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Location Settings'), findsAtLeastNWidgets(1));
    });

    testWidgets('tapping Location in SettingsScreen navigates to it',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();
      expect(find.byType(LocationSettingsScreen), findsOneWidget);
    });
  });
}
