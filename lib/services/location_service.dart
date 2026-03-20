import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../backend_url.dart';
import 'api_service.dart';

/// Service for obtaining GPS location and sending it to the backend.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Gets the current device position if permission is granted.
  /// Returns null if location services are disabled or permission denied.
  Future<Position?> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      debugPrint('Location services disabled');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('Location permission denied');
      return null;
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 10),
    );
  }

  /// Sends the current device location to the UserService backend.
  /// Returns true on success.
  Future<bool> updateBackendLocation() async {
    final position = await getCurrentPosition();
    if (position == null) return false;

    final profileId = await AppState().getOrResolveProfileId();
    if (profileId == null) {
      debugPrint('Cannot update location: no profile ID');
      return false;
    }

    final token = await AppState().getOrRefreshAuthToken();
    if (token == null) {
      debugPrint('Cannot update location: no auth token');
      return false;
    }

    try {
      final url =
          '${ApiUrls.userService}/api/userprofiles/$profileId/location';
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'city': '',
          'state': '',
          'country': '',
        }),
      );

      if (response.statusCode == 204) {
        debugPrint(
            'Location updated: ${position.latitude}, ${position.longitude}');
        return true;
      }
      debugPrint('Location update failed: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Location update error: $e');
      return false;
    }
  }
}
