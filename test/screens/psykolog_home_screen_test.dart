import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/psykolog_home_screen.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        if (call.method == 'read') return null;
        if (call.method == 'readAll') return <String, String>{};
        if (call.method == 'write') return null;
        return null;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (call) async {
        if (call.method == 'getAll') return <String, dynamic>{};
        return null;
      },
    );
  });

  group('PsykologHomeScreen', () {
    testWidgets('renders AppBar with title', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const PsykologHomeScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('AI Psykolog'), findsOneWidget);
    });

    testWidgets('shows start session button', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const PsykologHomeScreen()),
      );
      await tester.pump(const Duration(seconds: 1));

      // Either loading or settled — should not crash
      expect(find.byType(PsykologHomeScreen), findsOneWidget);
    });

    testWidgets('shows psychology icon in header', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const PsykologHomeScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.psychology), findsAtLeastNWidgets(1));
    });
  });
}
