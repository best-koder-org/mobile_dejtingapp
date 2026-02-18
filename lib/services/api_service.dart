import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../backend_url.dart';
import '../config/environment.dart';
import '../utils/jwt_utils.dart';

class AuthService {
  static EnvironmentSettings get _env => EnvironmentConfig.settings;

  static Future<Map<String, dynamic>?> login(
    String username,
    String password,
  ) async {
    try {
      final response = await http.post(
        _env.keycloakTokenEndpoint,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'password',
          'client_id': _env.keycloakClientId,
          'username': username,
          'password': password,
          'scope': _env.keycloakScopes.join(' '),
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }

      debugPrint(
        'Keycloak login failed (${response.statusCode}): ${response.body}',
      );
      return null;
    } catch (e, stack) {
      debugPrint('Keycloak login error: $e');
      debugPrint('$stack');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        _env.keycloakTokenEndpoint,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'client_id': _env.keycloakClientId,
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }

      debugPrint(
        'Keycloak refresh failed (${response.statusCode}): ${response.body}',
      );
      return null;
    } catch (e, stack) {
      debugPrint('Keycloak refresh error: $e');
      debugPrint('$stack');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchUserInfo(
    String accessToken,
  ) async {
    try {
      final response = await http.get(
        _env.keycloakUserInfoEndpoint,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }

      debugPrint(
        'Keycloak userinfo failed (${response.statusCode}): ${response.body}',
      );
      return null;
    } catch (e, stack) {
      debugPrint('Keycloak userinfo error: $e');
      debugPrint('$stack');
      return null;
    }
  }

  static Future<void> logout({String? refreshToken}) async {
    if (refreshToken == null || refreshToken.isEmpty) {
      return;
    }

    try {
      await http.post(
        _env.keycloakLogoutEndpoint,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': _env.keycloakClientId,
          'refresh_token': refreshToken,
        },
      );
    } catch (e, stack) {
      debugPrint('Keycloak logout error: $e');
      debugPrint('$stack');
    }
  }
}

class PhotoService {
  static String get baseUrl => ApiUrls.photoService;

  static Future<String?> uploadPhoto(String filePath) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/photos'),
      );
      request.files.add(await http.MultipartFile.fromPath('Photo', filePath));

      var response = await request.send();

      if (response.statusCode == 200) {
        String responseString = await response.stream.bytesToString();
        Map<String, dynamic> responseData = json.decode(responseString);
        return responseData['url'];
      }
      return null;
    } catch (e) {
      print('Photo upload error: $e');
      return null;
    }
  }

  static Future<bool> deletePhoto(String photoId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/photos/$photoId'),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Photo delete error: $e');
      return false;
    }
  }
}

class MatchmakingService {
  static String get baseUrl =>
      ApiUrls.matchmakingService; // Use dynamic URL configuration

  static Future<List<Map<String, dynamic>>> getProfiles(String userId) async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      if (token == null) {
        debugPrint('Get profiles aborted: no access token');
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/matchmaking/profiles/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Get profiles error: $e');
      return [];
    }
  }

  static Future<bool> swipeProfile(
    String userId,
    String targetUserId,
    bool isLike,
  ) async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      if (token == null) {
        debugPrint('Swipe aborted: no access token');
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/matchmaking/swipe'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'userId': userId,
          'targetUserId': targetUserId,
          'isLike': isLike,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Swipe error: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getMatches(String userId) async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      if (token == null) {
        debugPrint('Get matches aborted: no access token');
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/matchmaking/matches/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Get matches error: $e');
      return [];
    }
  }
}

class UserService {
  static String get baseUrl =>
      ApiUrls.userService; // Use dynamic URL configuration

  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      if (token == null) {
        debugPrint('Get user profile aborted: no access token');
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Get user profile error: $e');
      return null;
    }
  }

  static Future<bool> updateUserProfile(
    String userId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      if (token == null) {
        debugPrint('Update user profile aborted: no access token');
        return false;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(profileData),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Update user profile error: $e');
      return false;
    }
  }
}

// Singleton class to manage app state
class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  static const _accessTokenKey = 'accessToken';
  static const _refreshTokenKey = 'refreshToken';
  static const _idTokenKey = 'idToken';
  static const _accessTokenExpiryKey = 'accessTokenExpiry';
  static const _refreshTokenExpiryKey = 'refreshTokenExpiry';
  static const _userIdKey = 'userId';
  static const _userProfileKey = 'userProfile';
  static const _onboardingCompleteKey = 'onboardingComplete';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _userId;
  String? _accessToken;
  String? _refreshToken;
  String? _idToken;
  DateTime? _accessTokenExpiresAt;
  DateTime? _refreshTokenExpiresAt;
  Map<String, dynamic>? _userProfile;
  bool _initialized = false;
  bool _onboardingComplete = false;

  String? get userId => _userId;
  String? get authToken => _accessToken;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get userProfile => _userProfile;
  DateTime? get accessTokenExpiresAt => _accessTokenExpiresAt;
  DateTime? get refreshTokenExpiresAt => _refreshTokenExpiresAt;
  bool get isInitialized => _initialized;
  bool get isOnboardingComplete => _onboardingComplete;

  bool hasValidAuthSession(
      {Duration gracePeriod = const Duration(minutes: 1)}) {
    if (_userId == null || _accessToken == null) {
      return false;
    }

    return !_isAccessTokenExpired(gracePeriod: gracePeriod);
  }

  Future<void> setOnboardingComplete() async {
    _onboardingComplete = true;
    await _storage.write(key: _onboardingCompleteKey, value: 'true');
  }

  Future<void> initialize({bool forceRefresh = false}) async {
    if (_initialized && !forceRefresh) {
      return;
    }

    _accessToken ??= await _storage.read(key: _accessTokenKey) ??
        await _storage.read(key: 'jwt');
    _refreshToken ??= await _storage.read(key: _refreshTokenKey);
    _idToken ??= await _storage.read(key: _idTokenKey);
    _userId ??= await _storage.read(key: _userIdKey);

    _accessTokenExpiresAt ??=
        _parseDate(await _storage.read(key: _accessTokenExpiryKey)) ??
            (_accessToken != null
                ? JwtUtils.getExpiration(_accessToken!)
                : null);
    _refreshTokenExpiresAt ??=
        _parseDate(await _storage.read(key: _refreshTokenExpiryKey));

    if (_userProfile == null) {
      final storedProfile = await _storage.read(key: _userProfileKey);
      if (storedProfile != null) {
        try {
          _userProfile = json.decode(storedProfile) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('Failed to decode stored user profile: $e');
        }
      }
    }

    _onboardingComplete =
        (await _storage.read(key: _onboardingCompleteKey)) == 'true';

    _initialized = true;
  }

  Future<void> login({
    required String userId,
    required String accessToken,
    required DateTime accessTokenExpiresAt,
    required String refreshToken,
    DateTime? refreshTokenExpiresAt,
    String? idToken,
    Map<String, dynamic>? profile,
  }) async {
    _userId = userId;
    _userProfile = profile;
    _initialized = true;

    await _saveTokens(
      accessToken: accessToken,
      accessTokenExpiresAt: accessTokenExpiresAt,
      refreshToken: refreshToken,
      refreshTokenExpiresAt: refreshTokenExpiresAt,
      idToken: idToken,
    );

    await Future.wait([
      _storage.write(key: _userIdKey, value: userId),
      if (profile != null)
        _storage.write(key: _userProfileKey, value: json.encode(profile))
      else
        _storage.delete(key: _userProfileKey),
    ]);
  }

  Future<String?> getOrRefreshAuthToken({
    Duration gracePeriod = const Duration(minutes: 5),
  }) async {
    await initialize();

    if (_accessToken != null &&
        !_isAccessTokenExpired(gracePeriod: gracePeriod)) {
      return _accessToken;
    }

    if (_refreshToken == null || _refreshToken!.isEmpty) {
      await _invalidateCachedSession();
      return null;
    }

    final refreshed = await AuthService.refreshToken(_refreshToken!);
    if (refreshed == null) {
      await _invalidateCachedSession();
      return null;
    }

    final String? newAccessToken = refreshed['access_token'] as String?;
    final String? newRefreshToken =
        refreshed['refresh_token'] as String? ?? _refreshToken;
    if (newAccessToken == null || newRefreshToken == null) {
      await _invalidateCachedSession();
      return null;
    }

    final int? expiresIn = _readInt(refreshed['expires_in']);
    final int? refreshExpiresIn = _readInt(refreshed['refresh_expires_in']);
    final String? newIdToken = refreshed['id_token'] as String? ?? _idToken;

    final accessTokenTtl = expiresIn != null && expiresIn > 0 ? expiresIn : 300;
    final accessExpiresAt =
        DateTime.now().toUtc().add(Duration(seconds: accessTokenTtl));
    final refreshExpiresAt = refreshExpiresIn != null
        ? DateTime.now().toUtc().add(Duration(seconds: refreshExpiresIn))
        : _refreshTokenExpiresAt;

    await _saveTokens(
      accessToken: newAccessToken,
      accessTokenExpiresAt: accessExpiresAt,
      refreshToken: newRefreshToken,
      refreshTokenExpiresAt: refreshExpiresAt,
      idToken: newIdToken,
    );

    return _accessToken;
  }

  Future<void> logout() async {
    await AuthService.logout(refreshToken: _refreshToken);

    _userId = null;
    _userProfile = null;
    _initialized = false;

    await Future.wait([
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _userProfileKey),
    ]);

    await _clearTokenStorage();
    _initialized = false;
  }

  Future<void> updateProfile(Map<String, dynamic> profile) async {
    _userProfile = profile;
    await _storage.write(key: _userProfileKey, value: json.encode(profile));
  }

  Future<void> _saveTokens({
    required String accessToken,
    required DateTime accessTokenExpiresAt,
    required String refreshToken,
    DateTime? refreshTokenExpiresAt,
    String? idToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _idToken = idToken;
    _accessTokenExpiresAt = accessTokenExpiresAt.toUtc();
    _refreshTokenExpiresAt = refreshTokenExpiresAt?.toUtc();

    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(
        key: _accessTokenExpiryKey,
        value: _accessTokenExpiresAt!.toIso8601String(),
      ),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      if (_refreshTokenExpiresAt != null)
        _storage.write(
          key: _refreshTokenExpiryKey,
          value: _refreshTokenExpiresAt!.toIso8601String(),
        )
      else
        _storage.delete(key: _refreshTokenExpiryKey),
      if (idToken != null)
        _storage.write(key: _idTokenKey, value: idToken)
      else
        _storage.delete(key: _idTokenKey),
      _storage.delete(key: 'jwt'),
    ]);
  }

  Future<void> _invalidateCachedSession() async {
    _accessToken = null;
    _refreshToken = null;
    _idToken = null;
    _accessTokenExpiresAt = null;
    _refreshTokenExpiresAt = null;

    await _clearTokenStorage();
  }

  Future<void> _clearTokenStorage() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _accessTokenExpiryKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _refreshTokenExpiryKey),
      _storage.delete(key: _idTokenKey),
      _storage.delete(key: 'jwt'),
    ]);
  }

  bool _isAccessTokenExpired({required Duration gracePeriod}) {
    if (_accessToken == null) {
      return true;
    }

    if (_accessTokenExpiresAt != null) {
      final threshold = _accessTokenExpiresAt!.subtract(gracePeriod);
      return DateTime.now().toUtc().isAfter(threshold);
    }

    return JwtUtils.isExpired(_accessToken!, gracePeriod: gracePeriod);
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(raw).toUtc();
    } catch (_) {
      return null;
    }
  }

  int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
