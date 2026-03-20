import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:dejtingapp/services/location_service.dart';

class MockGeolocatorPlatform extends GeolocatorPlatform
    with MockPlatformInterfaceMixin {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  Position? position;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    if (position != null) return position!;
    throw const LocationServiceDisabledException();
  }
}

Position _fakePosition({
  double latitude = 59.3293,
  double longitude = 18.0686,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime(2025, 1, 1),
    accuracy: 10,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

void main() {
  late MockGeolocatorPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockGeolocatorPlatform();
    GeolocatorPlatform.instance = mockPlatform;
  });

  group('LocationService', () {
    group('getCurrentPosition', () {
      test('returns null when location service disabled', () async {
        mockPlatform.serviceEnabled = false;
        final result = await LocationService.instance.getCurrentPosition();
        expect(result, isNull);
      });

      test('returns null when permission denied', () async {
        mockPlatform.permission = LocationPermission.denied;
        // After requesting, still denied
        final result = await LocationService.instance.getCurrentPosition();
        expect(result, isNull);
      });

      test('returns null when permission deniedForever', () async {
        mockPlatform.permission = LocationPermission.deniedForever;
        final result = await LocationService.instance.getCurrentPosition();
        expect(result, isNull);
      });

      test('returns position when permission granted', () async {
        mockPlatform.permission = LocationPermission.whileInUse;
        mockPlatform.position = _fakePosition();
        final result = await LocationService.instance.getCurrentPosition();
        expect(result, isNotNull);
        expect(result!.latitude, 59.3293);
        expect(result.longitude, 18.0686);
      });

      test('returns position with always permission', () async {
        mockPlatform.permission = LocationPermission.always;
        mockPlatform.position = _fakePosition(latitude: 55.0, longitude: 13.0);
        final result = await LocationService.instance.getCurrentPosition();
        expect(result, isNotNull);
        expect(result!.latitude, 55.0);
      });
    });

    group('updateBackendLocation', () {
      test('returns false when no position available', () async {
        mockPlatform.serviceEnabled = false;
        final result =
            await LocationService.instance.updateBackendLocation();
        expect(result, isFalse);
      });
    });
  });
}
