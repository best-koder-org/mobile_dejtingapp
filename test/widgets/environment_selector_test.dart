import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/config/environment.dart';
import 'package:dejtingapp/widgets/environment_selector.dart';

import '../helpers/core_screen_test_helper.dart';

void main() {
  group('EnvironmentSelector', () {
    setUp(() => EnvironmentConfig.setEnvironment(Environment.development));
    tearDown(() => EnvironmentConfig.setEnvironment(Environment.development));

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const Scaffold(body: EnvironmentSelector()),
        ),
      );
      expect(find.byType(EnvironmentSelector), findsOneWidget);
    });

    testWidgets('shows environment options', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const Scaffold(body: EnvironmentSelector()),
        ),
      );
      expect(find.text('Development'), findsOneWidget);
      expect(find.text('Production'), findsOneWidget);
    });

    testWidgets('shows current environment name in header', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const Scaffold(body: EnvironmentSelector()),
        ),
      );
      expect(find.textContaining('Development'), findsWidgets);
    });

    testWidgets('tapping Development button keeps development environment',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const Scaffold(body: EnvironmentSelector()),
        ),
      );
      await tester.tap(find.text('Development'));
      await tester.pump();
      expect(EnvironmentConfig.isDevelopment, isTrue);
    });

    testWidgets('tapping Production switches environment',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const Scaffold(body: EnvironmentSelector()),
        ),
      );
      await tester.tap(find.text('Production'));
      await tester.pump();
      expect(EnvironmentConfig.isProduction, isTrue);
    });

    testWidgets('shows snackbar after switching to Production', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const Scaffold(body: EnvironmentSelector()),
        ),
      );
      await tester.tap(find.text('Production'));
      await tester.pump();
      expect(
        find.text('Switched to Production Environment'),
        findsOneWidget,
      );
    });

    testWidgets('shows snackbar after switching to Development', (tester) async {
      EnvironmentConfig.setEnvironment(Environment.production);
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const Scaffold(body: EnvironmentSelector()),
        ),
      );
      await tester.tap(find.text('Development'));
      await tester.pump();
      expect(
        find.text('Switched to Development Environment'),
        findsOneWidget,
      );
    });

    testWidgets('shows auto-detected host note when discovery is active',
        (tester) async {
      EnvironmentConfig.debugSetAutoLocalHost('localhost');
      addTearDown(() => EnvironmentConfig.debugSetAutoLocalHost(null));
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const Scaffold(body: EnvironmentSelector()),
        ),
      );
      // Expand the collapsed connection-settings panel.
      await tester.tap(find.byType(ExpansionTile).first);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Auto-detected host: localhost'),
        findsOneWidget,
      );
      expect(find.textContaining('DEV-only'), findsWidgets);
    });

    testWidgets('hides auto-detected note when discovery is inactive',
        (tester) async {
      EnvironmentConfig.debugSetAutoLocalHost(null);
      addTearDown(() => EnvironmentConfig.debugSetAutoLocalHost(null));
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const Scaffold(body: EnvironmentSelector()),
        ),
      );
      await tester.tap(find.byType(ExpansionTile).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Auto-detected host'), findsNothing);
    });

    testWidgets('shows no-backend guidance when auto host is not reachable',
        (tester) async {
      EnvironmentConfig.debugSetAutoLocalHost(null);
      addTearDown(() => EnvironmentConfig.debugSetAutoLocalHost(null));
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const Scaffold(body: EnvironmentSelector()),
        ),
      );
      await tester.tap(find.byType(ExpansionTile).first);
      await tester.pumpAndSettle();
      expect(find.text('No laptop backend reachable'), findsOneWidget);
      expect(find.textContaining('adb-reverse-laptop.sh'), findsOneWidget);
      expect(find.textContaining('same WiFi'), findsWidgets);
    });
  });

  group('EnvironmentInfo', () {
    setUp(() => EnvironmentConfig.setEnvironment(Environment.development));
    tearDown(() => EnvironmentConfig.setEnvironment(Environment.development));

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const Scaffold(body: EnvironmentInfo()),
        ),
      );
      expect(find.byType(EnvironmentInfo), findsOneWidget);
    });

    testWidgets('shows current environment name in uppercase', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const Scaffold(body: EnvironmentInfo()),
        ),
      );
      expect(find.text('DEVELOPMENT'), findsOneWidget);
    });

    testWidgets('shows production environment name when switched',
        (tester) async {
      EnvironmentConfig.setEnvironment(Environment.production);
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const Scaffold(body: EnvironmentInfo()),
        ),
      );
      expect(find.text('PRODUCTION'), findsOneWidget);
    });
  });
}
