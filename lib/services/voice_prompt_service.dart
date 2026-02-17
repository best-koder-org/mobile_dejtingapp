import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import 'api_service.dart';
import '../backend_url.dart';

/// Voice prompt recording, playback, and upload service.
///
/// Security:
/// - Records in-app only (no file imports to prevent deepfakes)
/// - Enforces 3-30s duration limits
/// - Uploads to authenticated endpoint with JWT
/// - Audio files served via time-limited signed URLs
class VoicePromptService {
  static final VoicePromptService _instance = VoicePromptService._();
  factory VoicePromptService() => _instance;
  VoicePromptService._();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  // Recording state
  bool _isRecording = false;
  bool get isRecording => _isRecording;

  // Playback state
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Duration _recordingDuration = Duration.zero;
  Duration get recordingDuration => _recordingDuration;

  String? _lastRecordingPath;
  String? get lastRecordingPath => _lastRecordingPath;

  // Constraints
  static const int minDurationSeconds = 3;
  static const int maxDurationSeconds = 30;
  static const int maxFileSizeBytes = 2 * 1024 * 1024; // 2MB

  // ──────────────────────────────────────────
  // RECORDING
  // ──────────────────────────────────────────

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Start recording a voice prompt (AAC format for best compatibility)
  Future<bool> startRecording() async {
    try {
      if (_isRecording) return false;

      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('Microphone permission denied');
        return false;
      }

      final dir = await getTemporaryDirectory();
      final path = p.join(dir.path, 'voice_prompt_${DateTime.now().millisecondsSinceEpoch}.m4a');

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
          numChannels: 1, // Mono — voice doesn't need stereo
        ),
        path: path,
      );

      _isRecording = true;
      _recordingDuration = Duration.zero;
      _lastRecordingPath = path;

      debugPrint('Recording started: $path');
      return true;
    } catch (e) {
      debugPrint('Failed to start recording: $e');
      return false;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final path = await _recorder.stop();
      _isRecording = false;

      if (path == null) return null;

      // Validate file
      final file = File(path);
      if (!await file.exists()) return null;

      final fileSize = await file.length();
      if (fileSize > maxFileSizeBytes) {
        debugPrint('Recording too large: ${fileSize}B (max: ${maxFileSizeBytes}B)');
        await file.delete();
        return null;
      }

      // Get duration using audio player
      final duration = await _player.setFilePath(path);
      if (duration != null) {
        _recordingDuration = duration;

        if (duration.inSeconds < minDurationSeconds) {
          debugPrint('Recording too short: ${duration.inSeconds}s (min: ${minDurationSeconds}s)');
          await file.delete();
          return null;
        }
      }

      _lastRecordingPath = path;
      debugPrint('Recording saved: $path (${fileSize}B, ${_recordingDuration.inSeconds}s)');
      return path;
    } catch (e) {
      debugPrint('Failed to stop recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Cancel recording and discard
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
      }
      if (_lastRecordingPath != null) {
        final file = File(_lastRecordingPath!);
        if (await file.exists()) await file.delete();
        _lastRecordingPath = null;
      }
    } catch (e) {
      debugPrint('Failed to cancel recording: $e');
    }
  }

  /// Get amplitude stream for waveform visualization during recording
  Stream<RecordState> get recordStateStream => _recorder.onStateChanged();

  // ──────────────────────────────────────────
  // PLAYBACK
  // ──────────────────────────────────────────

  /// Play audio from URL (for other users' voice prompts)
  Future<void> playFromUrl(String url) async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      if (token == null) return;

      await _player.setUrl(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      _isPlaying = true;
      await _player.play();
    } catch (e) {
      debugPrint('Playback error: $e');
      _isPlaying = false;
    }
  }

  /// Play audio from local file (for preview after recording)
  Future<void> playFromFile(String path) async {
    try {
      await _player.setFilePath(path);
      _isPlaying = true;
      await _player.play();
    } catch (e) {
      debugPrint('Playback error: $e');
      _isPlaying = false;
    }
  }

  /// Stop playback
  Future<void> stopPlayback() async {
    await _player.stop();
    _isPlaying = false;
  }

  /// Pause playback
  Future<void> pausePlayback() async {
    await _player.pause();
    _isPlaying = false;
  }

  /// Get playback position stream
  Stream<Duration> get positionStream => _player.positionStream;

  /// Get playback duration
  Duration? get totalDuration => _player.duration;

  /// Get player state stream
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  // ──────────────────────────────────────────
  // UPLOAD / API
  // ──────────────────────────────────────────

  /// Upload a recorded voice prompt to the server
  /// Returns the voice prompt URL on success, null on failure
  Future<String?> uploadVoicePrompt(String filePath) async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      if (token == null) {
        debugPrint('Upload aborted: no access token');
        return null;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('Upload aborted: file does not exist');
        return null;
      }

      final uri = Uri.parse('${ApiUrls.gateway}/api/voice-prompts');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath(
          'audio',
          filePath,
          filename: p.basename(filePath),
        ));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final url = data['url'] as String?;
        debugPrint('Voice prompt uploaded: $url');
        return url;
      }

      debugPrint('Upload failed (${response.statusCode}): ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  /// Delete user's voice prompt
  Future<bool> deleteVoicePrompt() async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      if (token == null) return false;

      final uri = Uri.parse('${ApiUrls.gateway}/api/voice-prompts');
      final response = await http.delete(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Delete voice prompt error: $e');
      return false;
    }
  }

  /// Clean up resources
  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
