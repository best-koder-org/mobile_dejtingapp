import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../backend_url.dart';
import 'api_service.dart';
import 'http_client_factory.dart';

/// Uploads dev-only user feedback (voice memos + metadata) to bot-service.
///
/// The endpoint `/api/userfeedback` is allow-anonymous via the gateway, so the
/// auth token is best-effort — if one is available we forward it so the server
/// can record the submitter's Keycloak subject claim.
class FeedbackService {
  final http.Client _httpClient;
  final Future<String?> Function() _tokenProvider;

  FeedbackService({
    http.Client? httpClient,
    Future<String?> Function()? tokenProvider,
  })  : _httpClient = httpClient ?? createPlatformHttpClient(),
        _tokenProvider =
            tokenProvider ?? (() => AppState().getOrRefreshAuthToken());

  /// Posts a feedback row. At least one of [audioFile] or [noteText] must be set.
  /// Returns the server's response body (JSON) on success.
  Future<Map<String, dynamic>> submit({
    File? audioFile,
    String? noteText,
    int durationSec = 0,
    String? screen,
    String? appVersion,
  }) async {
    if (audioFile == null && (noteText == null || noteText.trim().isEmpty)) {
      throw ArgumentError('Provide an audio file or a noteText.');
    }

    final uri = Uri.parse('${ApiUrls.gateway}/api/userfeedback');
    final request = http.MultipartRequest('POST', uri);

    String? token;
    try {
      token = await _tokenProvider();
    } catch (_) {
      token = null;
    }
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (audioFile != null) {
      final ext = p.extension(audioFile.path).toLowerCase();
      final filename = 'memo${ext.isEmpty ? '.m4a' : ext}';
      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
        filename: filename,
      ));
    }

    if (noteText != null && noteText.trim().isNotEmpty) {
      request.fields['noteText'] = noteText.trim();
    }
    request.fields['durationSec'] = durationSec.toString();
    if (screen != null && screen.isNotEmpty) {
      request.fields['screen'] = screen;
    }
    request.fields['appVersion'] = appVersion ?? 'dev';

    debugPrint('FeedbackService: POST $uri (audio=${audioFile != null}, '
        'note=${noteText?.length ?? 0} chars, screen=$screen)');
    debugPrint('FeedbackService: _httpClient is ${_httpClient.runtimeType}');

    final http.StreamedResponse streamed;
    try {
      streamed = await _httpClient.send(request);
    } catch (e, stack) {
      debugPrint('FeedbackService: send threw ${e.runtimeType}: $e');
      debugPrint('$stack');
      rethrow;
    }
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return <String, dynamic>{};
      final decoded = json.decode(response.body);
      return decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'value': decoded};
    }
    debugPrint('FeedbackService: failed ${response.statusCode} ${response.body}');
    throw Exception('Feedback upload failed: ${response.statusCode}');
  }

  /// Fetches a single feedback row by id. Returns null on 404.
  /// Used to poll for the server-side transcript after submission.
  Future<Map<String, dynamic>?> fetchById(int id) async {
    final uri = Uri.parse('${ApiUrls.gateway}/api/userfeedback/$id');
    final resp = await _httpClient.get(uri);
    if (resp.statusCode == 404) return null;
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('fetchById failed: ${resp.statusCode}');
    }
    if (resp.body.isEmpty) return null;
    final decoded = json.decode(resp.body);
    return decoded is Map<String, dynamic> ? decoded : null;
  }
}
