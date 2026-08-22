import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../services/api_service.dart' show AppState;
import '../services/feedback_service.dart';

/// Returns a human label for the current logged-in user, or null if anonymous.
/// Reads from [AppState] singleton without touching disk. Visible in tests as
/// null because AppState is not initialized.
String? _currentUserLabel() {
  final profile = AppState().userProfile;
  if (profile == null) return null;
  final name = (profile['displayName'] ??
          profile['preferred_username'] ??
          profile['email'])
      ?.toString();
  if (name == null || name.isEmpty) return null;
  return name;
}

/// Compile-time visibility flag. Visible in debug builds OR when the build was
/// compiled with `--dart-define=DEJTING_FEEDBACK_VISIBLE=true`.
bool get feedbackFabEnabled =>
    kDebugMode ||
    const bool.fromEnvironment('DEJTING_FEEDBACK_VISIBLE', defaultValue: false);

/// Global navigator key used by the FAB to show its bottom sheet from above
/// MaterialApp's Navigator (where Navigator.of(context) would be null).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Minimal recorder surface used by the feedback sheet, so it can be faked in
/// widget tests without a real microphone.
abstract class FeedbackRecorder {
  Future<bool> hasPermission();
  Future<void> start(RecordConfig config, {required String path});
  Future<String?> stop();
  Stream<Amplitude> onAmplitudeChanged(Duration interval);
  void dispose();
}

/// Adapter over the `record` package's [AudioRecorder].
class RecordAudioRecorder implements FeedbackRecorder {
  final AudioRecorder _impl;
  RecordAudioRecorder([AudioRecorder? impl]) : _impl = impl ?? AudioRecorder();

  @override
  Future<bool> hasPermission() => _impl.hasPermission();

  @override
  Future<void> start(RecordConfig config, {required String path}) =>
      _impl.start(config, path: path);

  @override
  Future<String?> stop() => _impl.stop();

  @override
  Stream<Amplitude> onAmplitudeChanged(Duration interval) =>
      _impl.onAmplitudeChanged(interval);

  @override
  void dispose() => _impl.dispose();
}

/// Draggable mini-FAB that records a short voice memo and uploads it to
/// bot-service. Tap = open sheet (record/text). Hidden in production by default.
class FeedbackFab extends StatefulWidget {
  final FeedbackService? service;
  final AudioRecorder? recorder;
  final String? currentScreenLabel;

  const FeedbackFab({
    super.key,
    this.service,
    this.recorder,
    this.currentScreenLabel,
  });

  @override
  State<FeedbackFab> createState() => _FeedbackFabState();
}

class _FeedbackFabState extends State<FeedbackFab> {
  late final FeedbackService _service = widget.service ?? FeedbackService();
  late final FeedbackRecorder _recorder = RecordAudioRecorder(widget.recorder);

  Offset _position = const Offset(16, 240);
  bool _isUploading = false;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!feedbackFabEnabled) return const SizedBox.shrink();

    final size = MediaQuery.of(context).size;
    // Respect system navigation bar / safe area so the FAB can't be dragged
    // beneath the native home/back buttons.
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final clampedX = _position.dx.clamp(0.0, size.width - 56);
    final clampedY = _position.dy.clamp(0.0, size.height - 56 - bottomPadding);

    return Positioned(
      left: clampedX,
      top: clampedY,
      // Use a GestureDetector at the same level so taps and pans don't fight
      // inside a Draggable. Tap → open sheet, pan → reposition the FAB.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isUploading ? null : () {
          if (kDebugMode) debugPrint('[FeedbackFab] tap → openSheet');
          _openSheet();
        },
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx).clamp(0.0, size.width - 56),
              (_position.dy + details.delta.dy).clamp(0.0, size.height - 56 - bottomPadding),
            );
          });
        },
        child: _buildFab(),
      ),
    );
  }

  Widget _buildFab({double opacity = 1.0}) {
    // The outer GestureDetector handles tap; this is a purely visual FAB.
    return IgnorePointer(
      child: Material(
        key: const Key('feedback-fab'),
        color: Colors.transparent,
        child: Opacity(
          opacity: opacity,
          child: FloatingActionButton.small(
            heroTag: 'feedback-fab',
            backgroundColor: Colors.deepPurple,
            onPressed: () {},
            tooltip: Overlay.maybeOf(context) != null ? 'Send feedback' : null,
            child: _isUploading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.mic, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Future<void> _openSheet() async {
    // Use the root navigator context (set in main.dart) because this widget
    // lives in MaterialApp.builder, above the actual Navigator.
    final navCtx = rootNavigatorKey.currentContext ?? context;
    final result = await showModalBottomSheet<_FeedbackResult>(
      context: navCtx,
      isScrollControlled: true,
      builder: (ctx) => FeedbackSheet(
        recorder: _recorder,
        screenLabel: widget.currentScreenLabel,
      ),
    );
    if (result == null) return;
    if (!mounted) return;

    setState(() => _isUploading = true);
    try {
      final response = await _service.submit(
        audioFile: result.audioPath != null ? File(result.audioPath!) : null,
        noteText: result.noteText,
        durationSec: result.durationSec,
        screen: widget.currentScreenLabel,
        appVersion: 'dev',
      );
      if (!mounted) return;
      final id = response['id'];
      final dialogCtx = rootNavigatorKey.currentContext ?? context;
      if (id is int && result.audioPath != null) {
        // ignore: use_build_context_synchronously
        await _showTranscriptDialog(dialogCtx, id);
      } else {
        ScaffoldMessenger.of(dialogCtx).showSnackBar(
          const SnackBar(content: Text('Feedback sent — thanks!')),
        );
      }
    } catch (e, stack) {
      if (kDebugMode) debugPrint('[FeedbackFab] submit failed: $e');
      if (kDebugMode) debugPrint('$stack');
      if (!mounted) return;
      final snackCtx = rootNavigatorKey.currentContext ?? context;
      ScaffoldMessenger.of(snackCtx).showSnackBar(
        SnackBar(content: Text('Feedback failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  /// Polls the server for the transcript and shows it to the user.
  /// Times out after ~5 minutes (whisper cold-start + processing can take
  /// a while on the laptop watcher).
  Future<void> _showTranscriptDialog(BuildContext context, int id) async {
    final completer = Completer<String?>();
    var attempts = 0;
    const maxAttempts = 60; // ~5 min at 5s interval

    final poll = Timer.periodic(const Duration(seconds: 5), (t) async {
      attempts++;
      try {
        final row = await _service.fetchById(id);
        final tx = row?['transcript'];
        if (tx is String && tx.isNotEmpty) {
          t.cancel();
          if (!completer.isCompleted) completer.complete(tx);
        }
      } catch (_) {/* ignore transient */}
      if (attempts >= maxAttempts && !completer.isCompleted) {
        t.cancel();
        completer.complete(null);
      }
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FutureBuilder<String?>(
        future: completer.future,
        builder: (c, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return AlertDialog(
              title: const Text('Transcribing…'),
              content: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Text('Waiting for Whisper to process…')),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    poll.cancel();
                    if (!completer.isCompleted) completer.complete(null);
                  },
                  child: const Text('Hide'),
                ),
              ],
            );
          }
          final transcript = snap.data;
          return AlertDialog(
            title: Text(transcript == null
                ? 'Transcript not ready'
                : 'You said (feedback #$id)'),
            content: SingleChildScrollView(
              child: Text(
                transcript ??
                    'No transcript after 5 min.\nThe audio is saved — '
                        'process-feedback.py will pick it up.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(c).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      ),
    );
    poll.cancel();
  }
}

class _FeedbackResult {
  final String? audioPath;
  final int durationSec;
  final String? noteText;
  _FeedbackResult({this.audioPath, this.durationSec = 0, this.noteText});
}

class FeedbackSheet extends StatefulWidget {
  final FeedbackRecorder recorder;
  final String? screenLabel;
  const FeedbackSheet({super.key, required this.recorder, this.screenLabel});

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  final TextEditingController _noteCtl = TextEditingController();
  bool _isRecording = false;
  String? _recordedPath;
  DateTime? _recordingStart;
  int _durationSec = 0;
  AudioPlayer? _player;
  bool _isPlaying = false;

  // Live waveform: a sliding window of normalized amplitudes (0..1).
  final List<double> _amps = List<double>.filled(40, 0.0, growable: true);
  StreamSubscription<Amplitude>? _ampSub;
  Timer? _tickTimer;

  @override
  void dispose() {
    _ampSub?.cancel();
    _tickTimer?.cancel();
    _player?.dispose();
    _noteCtl.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;

    bool hasPerm = false;
    try {
      hasPerm = await widget.recorder.hasPermission();
    } catch (e) {
      if (kDebugMode) debugPrint('[FeedbackFab] permission check failed: $e');
    }
    if (!hasPerm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path,
        'feedback_${DateTime.now().millisecondsSinceEpoch}.m4a');
    try {
      await widget.recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[FeedbackFab] start failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start recording — try again')),
        );
      }
      return;
    }
    // Stream amplitudes ~10x/s for the waveform UI.
    _ampSub = widget.recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
      // amp.current is in dBFS (typically -160..0). Map to 0..1.
      final db = amp.current;
      final norm = ((db + 45.0) / 45.0).clamp(0.0, 1.0);
      if (!mounted) return;
      setState(() {
        _amps.removeAt(0);
        _amps.add(norm);
      });
    });
    // Tick the elapsed-time label.
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _recordingStart == null) return;
      setState(() {
        _durationSec =
            DateTime.now().difference(_recordingStart!).inSeconds;
      });
    });
    setState(() {
      _isRecording = true;
      _recordedPath = null;
      _recordingStart = DateTime.now();
      _durationSec = 0;
    });
  }

  Future<void> _stopRecording() async {
    // Stop the waveform stream + timer first (never block on cancellation).
    unawaited(_ampSub?.cancel());
    _ampSub = null;
    _tickTimer?.cancel();
    _tickTimer = null;

    String? path;
    try {
      path = await widget.recorder.stop().timeout(const Duration(seconds: 5));
    } catch (e) {
      if (kDebugMode) debugPrint('[FeedbackFab] stop failed: $e');
      path = null;
    }

    final ms = _recordingStart == null
        ? 0
        : DateTime.now().difference(_recordingStart!).inMilliseconds;
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordedPath = path;
      _durationSec = (ms / 1000).round();
      // Decay the bars so the UI shows a "done" state.
      for (var i = 0; i < _amps.length; i++) {
        _amps[i] = _amps[i] * 0.3;
      }
    });

    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording failed — please try again')),
      );
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _ensurePlayer() async {
    if (_player != null) return;
    _player = AudioPlayer();
    _player!.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state.playing);
    });
  }

  /// Play/pause the recorded memo so the tester can preview it before sending.
  Future<void> _togglePlayback() async {
    final path = _recordedPath;
    if (path == null || _isRecording) return;
    if (_isPlaying) {
      await _player?.pause();
      return; // playerStateStream flips _isPlaying
    }
    await _ensurePlayer();
    try {
      await _player!.setFilePath(path);
      await _player!.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playback failed: $e')),
        );
      }
    }
  }

  /// Delete the current recording so the tester can record a fresh one.
  Future<void> _deleteRecording() async {
    await _player?.stop();
    _isPlaying = false;
    final path = _recordedPath;
    if (path != null) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {/* best-effort cleanup */}
    }
    if (mounted) {
      setState(() {
        _recordedPath = null;
        _durationSec = 0;
        for (var i = 0; i < _amps.length; i++) {
          _amps[i] = 0.0;
        }
      });
    }
  }

  void _send() {
    final note = _noteCtl.text.trim();
    if (_recordedPath == null && note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record a memo or type a note first')),
      );
      return;
    }
    Navigator.of(context).pop(_FeedbackResult(
      audioPath: _recordedPath,
      durationSec: _durationSec,
      noteText: note.isEmpty ? null : note,
    ));
  }

  String _formatDuration(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final viewInsets = media.viewInsets;
    final viewPadding = media.viewPadding;
    final bottomInset = viewInsets.bottom + viewPadding.bottom;
    // Cap the sheet height (minus keyboard) and make the content scrollable so
    // the play/delete controls stay reachable on small phone screens instead of
    // throwing a RenderFlex overflow when the extra controls appear.
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Text(
            'Send feedback${widget.screenLabel != null ? ' • ${widget.screenLabel}' : ''}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Builder(builder: (_) {
            final label = _currentUserLabel();
            return Text(
              label != null
                  ? 'Submitting as $label'
                  : 'Submitting anonymously',
              key: const Key('feedback-identity-hint'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
            );
          }),
          const SizedBox(height: 16),
          // Live waveform display.
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: _isRecording ? Colors.red.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(
              painter: _WaveformPainter(
                amps: _amps,
                color: _isRecording ? Colors.red : Colors.blueGrey,
                active: _isRecording,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          // Status row: timer + state text.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecording) ...[
                const _BlinkingDot(),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  _isRecording
                      ? 'Recording • ${_formatDuration(_durationSec)}'
                      : (_recordedPath == null
                          ? 'Tap mic to start'
                          : 'Saved ${_formatDuration(_durationSec)} — play/delete below, or tap mic to redo'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tap-to-toggle mic button.
          Center(
            child: GestureDetector(
              key: const Key('feedback-mic-toggle'),
              onTap: _toggleRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.red : Colors.deepPurple,
                  boxShadow: [
                    if (_isRecording)
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
          // Preview & redo controls — visible once a recording exists.
          if (_recordedPath != null && !_isRecording) ...[
            const SizedBox(height: 12),
            FeedbackRecordingControls(
              isPlaying: _isPlaying,
              onPlay: _togglePlayback,
              onDelete: _deleteRecording,
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            key: const Key('feedback-note-input'),
            controller: _noteCtl,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Optional: type a note',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const Spacer(),
              FilledButton.icon(
                key: const Key('feedback-send-button'),
                onPressed: _isRecording ? null : _send,
                icon: const Icon(Icons.send),
                label: const Text('Send'),
              ),
            ],
          ),
            ],
          ),
        ),
      );
  }
}

/// Play / Delete controls shown after a voice memo has been recorded so the
/// tester can preview it before sending, or discard it and record a new one.
class FeedbackRecordingControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const FeedbackRecordingControls({
    super.key,
    required this.isPlaying,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          key: const Key('feedback-play-button'),
          onPressed: onPlay,
          icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
          label: Text(isPlaying ? 'Stop' : 'Play'),
        ),
        OutlinedButton.icon(
          key: const Key('feedback-delete-button'),
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete'),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
        ),
      ],
    );
  }
}

/// Paints a sliding-window amplitude bar chart.
class _WaveformPainter extends CustomPainter {
  final List<double> amps;
  final Color color;
  final bool active;
  _WaveformPainter({required this.amps, required this.color, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    if (amps.isEmpty) return;
    final paint = Paint()
      ..color = color.withValues(alpha: active ? 1.0 : 0.5)
      ..style = PaintingStyle.fill;
    final barW = size.width / amps.length;
    final mid = size.height / 2;
    for (var i = 0; i < amps.length; i++) {
      final h = math.max(2.0, amps[i] * size.height * 0.9);
      final rect = Rect.fromLTWH(
        i * barW + 1,
        mid - h / 2,
        barW - 2,
        h,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.amps != amps || old.active != active || old.color != color;
}

/// A small red dot that pulses while recording.
class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
        ..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
