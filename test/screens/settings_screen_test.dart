import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/settings_screen.dart';
import 'package:dejtingapp/screens/verification_selfie_screen.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('SettingsScreen', () {
    setUp(() {
      // SettingsScreen has a long ListView; increase viewport so all items visible
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.window.physicalSizeTestValue = const Size(800, 2400);
      binding.window.devicePixelRatioTestValue = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    testWidgets('renders scaffold with app bar', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows Settings title', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('shows Account section header', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Account'), findsOneWidget);
    });

    testWidgets('shows Edit Profile option', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Edit profile'), findsOneWidget);
    });

    testWidgets('shows distance slider', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Slider), findsAtLeastNWidgets(1));
    });

    testWidgets('shows age range slider', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(RangeSlider), findsOneWidget);
    });

    testWidgets('shows ListView for scrollable content', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows language option', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('LANGUAGES'), findsOneWidget);
    });

    testWidgets('shows logout button', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('about dialog shows localized version and description strings',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('About'));
      await tester.pump(const Duration(milliseconds: 500));
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
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Verify Your Account'));
      await tester.pump(); // Start the route transition
      await tester.pump(const Duration(milliseconds: 500)); // Complete it
      expect(find.byType(VerificationSelfieScreen), findsOneWidget);
    });

    testWidgets('shows Rate Us tile with star icon', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Rate Us'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('tapping Rate Us tile triggers _rateApp and shows snackbar fallback',
        (tester) async {
      // Mock url_launcher channel to return false (cannot launch)
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        (MethodCall methodCall) async => false,
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          null,
        );
      });

      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Rate Us'));
      // Allow async _rateApp to complete
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      // url_launcher returns false → snackbar fallback shown
      expect(
        find.text('Could not open the store page. Please try again later.'),
        findsOneWidget,
      );
    });

    testWidgets('has screen:settings semantics label', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const SettingsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byWidgetPredicate((w) => w is Semantics && (w as Semantics).properties.label == 'screen:settings'),
        findsOneWidget,
      );
    });
  });
}
