import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Captures a short voice note for dictation in the forum composer.
///
/// Deliberately only records — transcription goes through [ForumService.transcribe], so the
/// two concerns stay separate and the UI can show progress between them.
///
/// Recordings are capped at [maxSeconds] because a 200-character post is only about 20
/// seconds of speech, and it bounds what the speech engine has to chew on.
///
/// Web builds cannot record: the `record` plugin is mobile-only, so [isSupported] is false
/// and callers hide the microphone rather than failing at runtime.
class ForumVoiceService {
  ForumVoiceService({AudioRecorder? recorder}) : _recorder = recorder ?? AudioRecorder();

  /// Mirrors ForumService.maxVoiceSeconds and ForumLimits.MaxVoiceSeconds on the server.
  static const int maxSeconds = 20;

  final AudioRecorder _recorder;

  bool get isSupported => !kIsWeb;

  /// Whether the microphone may be used. False on web, where the plugin has no implementation.
  Future<bool> hasPermission() async =>
      isSupported && await _recorder.hasPermission();

  /// Starts recording. Returns the file path, or null when unavailable or not permitted.
  Future<String?> start() async {
    if (!isSupported) return null;
    if (!await _recorder.hasPermission()) return null;

    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'forum_note_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
        numChannels: 1, // mono — voice needs no stereo
      ),
      path: path,
    );

    return path;
  }

  /// Stops and returns the recording, or null when nothing usable was captured.
  Future<File?> stop() async {
    if (!isSupported) return null;

    final path = await _recorder.stop();
    if (path == null) return null;

    final file = File(path);
    if (!await file.exists()) return null;
    return file;
  }

  /// Stops and deletes the recording — used when the user abandons it.
  Future<void> cancel() async {
    if (!isSupported) return;

    final path = await _recorder.stop();
    if (path == null) return;

    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  Future<void> dispose() => _recorder.dispose();
}
