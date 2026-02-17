import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dejtingapp/l10n/generated/app_localizations.dart';
import 'package:dejtingapp/services/voice_prompt_service.dart';
import 'package:dejtingapp/theme/app_theme.dart';

/// Voice Prompt recording screen.
///
/// Security: Records in-app only (no file import) to prevent deepfakes.
/// Enforces 3-30 second duration limits client-side (validated again server-side).
class VoicePromptScreen extends StatefulWidget {
  const VoicePromptScreen({super.key});

  @override
  State<VoicePromptScreen> createState() => _VoicePromptScreenState();
}

class _VoicePromptScreenState extends State<VoicePromptScreen>
    with SingleTickerProviderStateMixin {
  final VoicePromptService _service = VoicePromptService();

  // State
  _ScreenState _state = _ScreenState.idle;
  int _secondsElapsed = 0;
  Timer? _timer;
  String? _recordedPath;
  bool _isUploading = false;
  String? _errorMessage;

  // Playback
  StreamSubscription<PlayerState>? _playerSub;

  // Animation for pulsing mic
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playerSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ──────────────── RECORDING ────────────────

  Future<void> _startRecording() async {
    final ok = await _service.startRecording();
    if (!ok) {
      setState(() {
        _errorMessage = 'Could not start recording. Check microphone permissions.';
      });
      return;
    }
    setState(() {
      _state = _ScreenState.recording;
      _secondsElapsed = 0;
      _errorMessage = null;
    });
    _pulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _secondsElapsed++);
      if (_secondsElapsed >= VoicePromptService.maxDurationSeconds) {
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    if (_secondsElapsed < VoicePromptService.minDurationSeconds) {
      await _service.cancelRecording();
      setState(() {
        _state = _ScreenState.idle;
        _errorMessage = 'Too short — record at least ${VoicePromptService.minDurationSeconds} seconds';
      });
      return;
    }

    final path = await _service.stopRecording();
    if (path == null) {
      setState(() {
        _state = _ScreenState.idle;
        _errorMessage = 'Recording failed. Please try again.';
      });
      return;
    }
    setState(() {
      _state = _ScreenState.preview;
      _recordedPath = path;
    });
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    await _service.cancelRecording();
    setState(() {
      _state = _ScreenState.idle;
      _secondsElapsed = 0;
    });
  }

  // ──────────────── PREVIEW PLAYBACK ────────────────

  Future<void> _playPreview() async {
    if (_recordedPath == null) return;
    await _service.playFromFile(_recordedPath!);
    setState(() => _state = _ScreenState.playing);
    _playerSub = _service.playerStateStream.listen((ps) {
      if (ps.processingState == ProcessingState.completed) {
        if (mounted) setState(() => _state = _ScreenState.preview);
      }
    });
  }

  Future<void> _stopPreview() async {
    await _service.stopPlayback();
    _playerSub?.cancel();
    setState(() => _state = _ScreenState.preview);
  }

  // ──────────────── UPLOAD ────────────────

  Future<void> _uploadAndSave() async {
    if (_recordedPath == null) return;
    setState(() => _isUploading = true);

    final url = await _service.uploadVoicePrompt(_recordedPath!);
    if (!mounted) return;

    if (url != null) {
      Navigator.pop(context, url);
    } else {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Upload failed. Please try again.';
      });
    }
  }

  void _retake() {
    _service.cancelRecording();
    setState(() {
      _state = _ScreenState.idle;
      _secondsElapsed = 0;
      _recordedPath = null;
      _errorMessage = null;
    });
  }

  // ──────────────── UI ────────────────

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () {
            _service.cancelRecording();
            Navigator.pop(context);
          },
        ),
        title: Text(
          l10n.voicePromptTitle,
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Instruction text
              Text(
                _state == _ScreenState.idle
                    ? l10n.voicePromptInstruction
                    : _state == _ScreenState.recording
                        ? l10n.voicePromptRecording
                        : l10n.voicePromptReview,
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Timer / waveform area
              Text(
                _formatTime(_secondsElapsed),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  color: _state == _ScreenState.recording
                      ? AppTheme.primaryColor
                      : AppTheme.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),

              // Progress bar
              if (_state == _ScreenState.recording)
                LinearProgressIndicator(
                  value: _secondsElapsed / VoicePromptService.maxDurationSeconds,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _secondsElapsed >= VoicePromptService.maxDurationSeconds - 5
                        ? Colors.orange
                        : AppTheme.primaryColor,
                  ),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),

              const Spacer(flex: 1),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Action buttons
              _buildActions(),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    switch (_state) {
      case _ScreenState.idle:
        return _buildRecordButton();
      case _ScreenState.recording:
        return _buildRecordingActions();
      case _ScreenState.preview:
      case _ScreenState.playing:
        return _buildPreviewActions();
    }
  }

  Widget _buildRecordButton() {
    return Column(
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: GestureDetector(
            onTap: _startRecording,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 40),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tap to record',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildRecordingActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Cancel
        GestureDetector(
          onTap: _cancelRecording,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
            child: const Icon(Icons.close, color: Colors.grey, size: 28),
          ),
        ),
        const SizedBox(width: 32),
        // Stop (pulsing)
        ScaleTransition(
          scale: _pulseAnimation,
          child: GestureDetector(
            onTap: _stopRecording,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.stop_rounded, color: Colors.white, size: 40),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewActions() {
    final isPlaying = _state == _ScreenState.playing;
    return Column(
      children: [
        // Play/Stop preview
        GestureDetector(
          onTap: isPlaying ? _stopPreview : _playPreview,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor,
            ),
            child: Icon(
              isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Save / Retake buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isUploading ? null : _retake,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                ),
                child: Text(
                  'Re-record',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadAndSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _ScreenState { idle, recording, preview, playing }
