import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:dejtingapp/screens/location_settings_screen.dart';
import 'package:dejtingapp/screens/settings_screen.dart';
import '../helpers/core_screen_test_helper.dart';

class MockGeolocatorPlatform extends GeolocatorPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.denied;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.denied;
}

void main() {
  setUp(() {
    GeolocatorPlatform.instance = MockGeolocatorPlatform();
  });

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

    testWidgets('shows permission status', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const LocationSettingsScreen()),
      );
      await tester.pumpAndSettle();
      // Permission denied by default mock
      expect(find.text('Permission required'), findsOneWidget);
    });

    testWidgets('shows enable location button when not permitted', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const LocationSettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Enable Location'), findsOneWidget);
    });

    testWidgets('shows location description text', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const LocationSettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('nearby'), findsOneWidget);
    });

    testWidgets('shows location icon', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const LocationSettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.my_location), findsOneWidget);
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
