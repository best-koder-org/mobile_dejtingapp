import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/settings_screen.dart';
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
  });
}
