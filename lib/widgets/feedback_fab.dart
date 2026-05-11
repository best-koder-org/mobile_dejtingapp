import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../services/feedback_service.dart';

/// Compile-time visibility flag. Visible in debug builds OR when the build was
/// compiled with `--dart-define=DEJTING_FEEDBACK_VISIBLE=true`.
bool get feedbackFabEnabled =>
    kDebugMode ||
    const bool.fromEnvironment('DEJTING_FEEDBACK_VISIBLE', defaultValue: false);

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
  late final AudioRecorder _recorder = widget.recorder ?? AudioRecorder();

  Offset _position = const Offset(16, 240);
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    if (!feedbackFabEnabled) return const SizedBox.shrink();

    final size = MediaQuery.of(context).size;
    final clampedX = _position.dx.clamp(0.0, size.width - 56);
    final clampedY = _position.dy.clamp(0.0, size.height - 56);

    return Positioned(
      left: clampedX,
      top: clampedY,
      child: Draggable(
        feedback: _buildFab(opacity: 0.85),
        childWhenDragging: const SizedBox(width: 56, height: 56),
        onDragEnd: (details) {
          setState(() {
            _position = Offset(
              details.offset.dx.clamp(0.0, size.width - 56),
              details.offset.dy.clamp(0.0, size.height - 56),
            );
          });
        },
        child: _buildFab(),
      ),
    );
  }

  Widget _buildFab({double opacity = 1.0}) {
    return Material(
      key: const Key('feedback-fab'),
      color: Colors.transparent,
      child: Opacity(
        opacity: opacity,
        child: FloatingActionButton.small(
          heroTag: 'feedback-fab',
          backgroundColor: Colors.deepPurple,
          onPressed: _isUploading ? null : _openSheet,
          tooltip: 'Send feedback',
          child: _isUploading
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.mic, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Future<void> _openSheet() async {
    final result = await showModalBottomSheet<_FeedbackResult>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _FeedbackSheet(
        recorder: _recorder,
        screenLabel: widget.currentScreenLabel,
      ),
    );
    if (result == null) return;
    if (!mounted) return;

    setState(() => _isUploading = true);
    try {
      await _service.submit(
        audioFile: result.audioPath != null ? File(result.audioPath!) : null,
        noteText: result.noteText,
        durationSec: result.durationSec,
        screen: widget.currentScreenLabel,
        appVersion: 'dev',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback sent — thanks!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}

class _FeedbackResult {
  final String? audioPath;
  final int durationSec;
  final String? noteText;
  _FeedbackResult({this.audioPath, this.durationSec = 0, this.noteText});
}

class _FeedbackSheet extends StatefulWidget {
  final AudioRecorder recorder;
  final String? screenLabel;
  const _FeedbackSheet({required this.recorder, this.screenLabel});

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final TextEditingController _noteCtl = TextEditingController();
  bool _isRecording = false;
  String? _recordedPath;
  DateTime? _recordingStart;
  int _durationSec = 0;

  @override
  void dispose() {
    _noteCtl.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPerm = await widget.recorder.hasPermission();
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
    await widget.recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    setState(() {
      _isRecording = true;
      _recordedPath = null;
      _recordingStart = DateTime.now();
    });
  }

  Future<void> _stopRecording() async {
    final path = await widget.recorder.stop();
    final ms = _recordingStart == null
        ? 0
        : DateTime.now().difference(_recordingStart!).inMilliseconds;
    setState(() {
      _isRecording = false;
      _recordedPath = path;
      _durationSec = (ms / 1000).round();
    });
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

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: 16 + viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Send feedback${widget.screenLabel != null ? ' • ${widget.screenLabel}' : ''}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            key: const Key('feedback-mic-hold'),
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecording(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red.shade100 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_isRecording ? Icons.mic : Icons.mic_none,
                      size: 32,
                      color: _isRecording ? Colors.red : Colors.black54),
                  const SizedBox(height: 6),
                  Text(_isRecording
                      ? 'Recording… release to stop'
                      : (_recordedPath == null
                          ? 'Hold to record voice memo'
                          : 'Recorded ${_durationSec}s — hold again to redo')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('feedback-note-input'),
            controller: _noteCtl,
            maxLines: 3,
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
                onPressed: _send,
                icon: const Icon(Icons.send),
                label: const Text('Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
