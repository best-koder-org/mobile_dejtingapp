import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../backend_url.dart';
import 'api_service.dart';

class VideoService {
  /// Upload a video file. Returns the video metadata including URL.
  static Future<Map<String, dynamic>?> uploadVideo(
    String filePath, {
    bool isProfileVideo = false,
  }) async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      if (token == null) throw Exception('Not authenticated');

      final uri = Uri.parse('${ApiUrls.gateway}/api/videos');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['isProfileVideo'] = isProfileVideo.toString()
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send().timeout(const Duration(seconds: 60));
      final body = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        return jsonDecode(body) as Map<String, dynamic>;
      }

      debugPrint('Video upload failed (${response.statusCode}): $body');
      return null;
    } catch (e) {
      debugPrint('Video upload error: $e');
      return null;
    }
  }

  /// Get list of user's videos.
  static Future<List<Map<String, dynamic>>> getVideos() async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      if (token == null) throw Exception('Not authenticated');

      final uri = Uri.parse('${ApiUrls.gateway}/api/videos');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return (body['clips'] as List<dynamic>?)
            ?.map((c) => c as Map<String, dynamic>)
            .toList() ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Video list error: $e');
      return [];
    }
  }

  /// Delete a video by ID.
  static Future<bool> deleteVideo(int videoId) async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      if (token == null) throw Exception('Not authenticated');

      final uri = Uri.parse('${ApiUrls.gateway}/api/videos/$videoId');
      final response = await http.delete(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Video delete error: $e');
      return false;
    }
  }

  /// Set a video as profile video.
  static Future<bool> setProfileVideo(int videoId) async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      if (token == null) throw Exception('Not authenticated');

      final uri = Uri.parse('${ApiUrls.gateway}/api/videos/$videoId/profile');
      final response = await http.put(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Set profile video error: $e');
      return false;
    }
  }

  /// Build the streaming URL for a video.
  static String getStreamUrl(dynamic videoId) {
    return '${ApiUrls.gateway}/api/videos/$videoId/stream';
  }
}
