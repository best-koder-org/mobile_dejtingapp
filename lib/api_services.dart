import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'models.dart';
import 'services/api_service.dart' as session;
import 'services/auth_session_manager.dart';
import 'services/swipe_service.dart';
import 'backend_url.dart';

class AuthApiService {
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final result = await AuthSessionManager.login(
      username: email,
      password: password,
    );

    if (!result.success) {
      throw Exception(result.message ?? 'Login failed');
    }

    final token = await session.AppState().getOrRefreshAuthToken();
    if (token == null || token.isEmpty) {
      throw Exception('Unable to retrieve access token after login.');
    }

    return token;
  }

  Future<void> logout() async {
    await session.AppState().logout();
  }

  Future<bool> isLoggedIn() async {
    await session.AppState().initialize();
    return session.AppState().userId != null;
  }

  /// Register opens the Keycloak registration portal — handled externally.
  /// This is a no-op placeholder; see screens/auth_screens.dart for actual flow.
  Future<void> register({
    required String username,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    // Registration is handled via Keycloak portal (URL_launcher)
    // This method exists for API compatibility only
    throw UnimplementedError(
      'Self-registration is handled via Keycloak portal. '
      'Use screens/auth_screens.dart RegisterScreen instead.',
    );
  }
}

class UserApiService {
  /// Create a user profile. Accepts a [UserProfile] or `Map<String, dynamic>`.
  Future<UserProfile> createProfile(dynamic payload) async {
    final Map<String, dynamic> data =
        payload is UserProfile ? payload.toJson() : payload as Map<String, dynamic>;
    final userId = session.AppState().userId;
    if (userId == null) throw Exception('Not authenticated');
    final success = await session.UserService.updateUserProfile(userId, data);
    if (!success) throw Exception('Failed to create profile.');
    final profile = await session.UserService.getUserProfile(userId);
    if (profile == null) throw Exception('Failed to retrieve created profile.');
    return UserProfile.fromJson(profile);
  }

  /// Get the current user's profile.
  Future<UserProfile?> getMyProfile() async {
    final userId = session.AppState().userId;
    if (userId == null) return null;
    final data = await session.UserService.getUserProfile(userId);
    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  /// Update a user profile. Accepts a [UserProfile] or `Map<String, dynamic>`.
  Future<UserProfile> updateProfile(dynamic payload) async {
    final Map<String, dynamic> data =
        payload is UserProfile ? payload.toJson() : payload as Map<String, dynamic>;
    final userId = session.AppState().userId;
    if (userId == null) throw Exception('Not authenticated');
    final success = await session.UserService.updateUserProfile(userId, data);
    if (!success) throw Exception('Failed to update profile.');
    final profile = await session.UserService.getUserProfile(userId);
    if (profile == null) throw Exception('Failed to retrieve updated profile.');
    return UserProfile.fromJson(profile);
  }

  /// Get current user ID from AppState.
  Future<String?> getCurrentUserId() async {
    await session.AppState().initialize();
    return session.AppState().userId;
  }

  /// Get a valid auth token (refreshes if needed).
  Future<String?> getAuthToken() async {
    return await session.AppState().getOrRefreshAuthToken();
  }

  /// Delete a photo by URL (delegates to PhotoService).
  Future<bool> deletePhoto(String photoUrl) async {
    return await session.PhotoService.deletePhoto(photoUrl);
  }
}

class MatchmakingApiService {
  /// Get candidate profiles for swiping.
  Future<List<MatchCandidate>> getCandidates({
    int page = 1,
    int pageSize = 20,
  }) async {
    // Matchmaking backend needs the integer profile ID, not Keycloak UUID
    final profileId = await session.AppState().getOrResolveProfileId();
    debugPrint('🔍 getCandidates: profileId=$profileId');
    if (profileId == null) { debugPrint('❌ getCandidates: profileId is null, returning []'); return []; }
    debugPrint('🔍 getCandidates: calling getProfiles($profileId)');
    final rawList = await session.MatchmakingService.getProfiles(profileId.toString());
    debugPrint('🔍 getCandidates: got ${rawList.length} raw items');
    return rawList.map((m) => MatchCandidate.fromJson(m)).toList();
  }

  /// Enhanced swipe with automatic retry and idempotency.
  Future<Map<String, dynamic>?> swipe({
    required String targetUserId,
    required bool isLike,
    String? idempotencyKey,
  }) async {
    return await SwipeService.swipe(
      targetUserId: targetUserId,
      direction: isLike ? SwipeDirection.like : SwipeDirection.pass,
      idempotencyKey: idempotencyKey,
    );
  }

  /// Get the current user's matches, enriched with names/photos from UserService.
  Future<List<MatchSummary>> getMatches() async {
    // Matchmaking backend needs the integer profile ID, not Keycloak UUID
    final profileId = await session.AppState().getOrResolveProfileId();
    if (profileId == null) return [];
    final rawList = await session.MatchmakingService.getMatches(profileId.toString());

    // Enrich match data with names/photos from UserService demo profiles
    Map<int, Map<String, dynamic>> profileLookup = {};
    try {
      final token = await session.AppState().getOrRefreshAuthToken();
      if (token != null) {
        final resp = await http.post(
          Uri.parse('${session.UserService.baseUrl}/api/demo/search'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: '{}',
        );
        if (resp.statusCode == 200) {
          final body = json.decode(resp.body);
          final List<dynamic> profiles = body['results'] ?? body['data']?['results'] ?? [];
          for (final p in profiles) {
            if (p is Map<String, dynamic> && p['id'] != null) {
              profileLookup[p['id'] as int] = p;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Match enrichment failed (non-fatal): $e');
    }


    // Fetch ProfileId -> Keycloak UUID mappings from SwipeService
    Map<int, String> keycloakIdLookup = {};
    try {
      final token = await session.AppState().getOrRefreshAuthToken();
      if (token != null) {
        final mappingResp = await http.get(
          Uri.parse('${ApiUrls.swipeService}/api/Swipes/user-mappings'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (mappingResp.statusCode == 200) {
          final mappingBody = json.decode(mappingResp.body);
          final List<dynamic> mappings = mappingBody['data'] ?? mappingBody;
          for (final mapping in mappings) {
            if (mapping is Map<String, dynamic>) {
              final pid = mapping['profileId'];
              final kcId = mapping['keycloakUserId']?.toString();
              if (pid != null && kcId != null) {
                keycloakIdLookup[pid is int ? pid : int.parse(pid.toString())] = kcId;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('User mapping fetch failed (non-fatal): $e');
    }

    final enriched = rawList.map((m) {
      final matchedId = m['matchedUserId'];
      final int? matchedIdInt = matchedId is int ? matchedId : int.tryParse(matchedId.toString());
      final found = matchedIdInt != null && profileLookup.containsKey(matchedIdInt);
      if (found) {
        final p = profileLookup[matchedIdInt]!;
        m['displayName'] = p['name'] ?? p['firstName'] ?? m['displayName'];
        m['name'] = p['name'] ?? p['firstName'] ?? m['name'];
        m['photoUrl'] = p['primaryPhotoUrl'] ?? p['photoUrl'] ?? m['photoUrl'];
        m['primaryPhotoUrl'] = p['primaryPhotoUrl'] ?? m['primaryPhotoUrl'];
      } else {
        // Fallback: use city + occupation from matchmaking data if available
        m['displayName'] = m['displayName'] ?? 'Match #$matchedIdInt';
        m['name'] = m['name'] ?? m['displayName'];
      }
      // Inject Keycloak UUID from mapping
      if (matchedIdInt != null && keycloakIdLookup.containsKey(matchedIdInt)) {
        m['keycloakUserId'] = keycloakIdLookup[matchedIdInt];
      }
      return MatchSummary.fromJson(m);
    }).toList();
    // Sort: enriched (with real names) first, then unknowns
    enriched.sort((a, b) {
      final aReal = !a.displayName.startsWith('Match #') && a.displayName != 'Unknown';
      final bReal = !b.displayName.startsWith('Match #') && b.displayName != 'Unknown';
      if (aReal && !bReal) return -1;
      if (!aReal && bReal) return 1;
      return b.matchedAt.compareTo(a.matchedAt); // newest first within group
    });
    return enriched;
  }
}

final authApi = AuthApiService();
final userApi = UserApiService();
final matchmakingApi = MatchmakingApiService();
