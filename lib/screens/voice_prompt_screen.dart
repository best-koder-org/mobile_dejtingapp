import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dejtingapp/l10n/generated/app_localizations.dart';
import 'package:dejtingapp/services/voice_prompt_service.dart';
import 'package:dejtingapp/theme/app_theme.dart';

/// Voice Prompt recording screen — Hinge-style direct flow.
///
/// Flow: tap mic → recording starts → tap stop → auto-uploads → done.
/// No preview step. If user doesn't like it, they delete from profile
/// and record again.
///
/// Security: Records in-app only (no file import) to prevent deepfakes.
/// Backend runs async Whisper.net moderation after upload.
class VoicePromptScreen extends StatefulWidget {
  const VoicePromptScreen({super.key});

  @override
  State<VoicePromptScreen> createState() => _VoicePromptScreenState();
}

class _VoicePromptScreenState extends State<VoicePromptScreen>
    with SingleTickerProviderStateMixin {
  final VoicePromptService _service = VoicePromptService();

  // State
  _Phase _phase = _Phase.idle;
  int _secondsElapsed = 0;
  Timer? _timer;
  String? _errorMessage;

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
      _phase = _Phase.recording;
      _secondsElapsed = 0;
      _errorMessage = null;
    });
    _pulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _secondsElapsed++);
      if (_secondsElapsed >= VoicePromptService.maxDurationSeconds) {
        _stopAndUpload();
      }
    });
  }

  /// Stop recording and immediately upload — no preview step.
  Future<void> _stopAndUpload() async {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    if (_secondsElapsed < VoicePromptService.minDurationSeconds) {
      await _service.cancelRecording();
      setState(() {
        _phase = _Phase.idle;
        _errorMessage =
            'Too short — record at least ${VoicePromptService.minDurationSeconds} seconds';
      });
      return;
    }

    final path = await _service.stopRecording();
    if (path == null) {
      setState(() {
        _phase = _Phase.idle;
        _errorMessage = 'Recording failed. Please try again.';
      });
      return;
    }

    // Go straight to uploading — no preview
    setState(() => _phase = _Phase.uploading);

    final url = await _service.uploadVoicePrompt(path);
    if (!mounted) return;

    if (url != null) {
      Navigator.pop(context, url);
    } else {
      setState(() {
        _phase = _Phase.idle;
        _errorMessage = 'Upload failed. Please try again.';
      });
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    await _service.cancelRecording();
    setState(() {
      _phase = _Phase.idle;
      _secondsElapsed = 0;
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
          style: const TextStyle(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
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
                _phase == _Phase.uploading
                    ? 'Saving your voice prompt…'
                    : _phase == _Phase.recording
                        ? l10n.voicePromptRecording
                        : l10n.voicePromptInstruction,
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Timer
              Text(
                _formatTime(_secondsElapsed),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  color: _phase == _Phase.recording
                      ? AppTheme.primaryColor
                      : AppTheme.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),

              // Progress bar (recording only)
              if (_phase == _Phase.recording)
                LinearProgressIndicator(
                  value: _secondsElapsed / VoicePromptService.maxDurationSeconds,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _secondsElapsed >=
                            VoicePromptService.maxDurationSeconds - 5
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
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Action area
              _buildAction(),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction() {
    switch (_phase) {
      case _Phase.idle:
        return _buildRecordButton();
      case _Phase.recording:
        return _buildRecordingControls();
      case _Phase.uploading:
        return _buildUploadingIndicator();
    }
  }

  Widget _buildRecordButton() {
    return Column(
      children: [
        GestureDetector(
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
            child:
                const Icon(Icons.mic_rounded, color: Colors.white, size: 40),
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

  Widget _buildRecordingControls() {
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
        // Stop & save (pulsing)
        ScaleTransition(
          scale: _pulseAnimation,
          child: GestureDetector(
            onTap: _stopAndUpload,
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
              child: const Icon(Icons.stop_rounded,
                  color: Colors.white, size: 40),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadingIndicator() {
    return Column(
      children: [
        const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(height: 16),
        Text(
          'Uploading…',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

/// Simple 3-phase state machine: idle → recording → uploading → done
enum _Phase { idle, recording, uploading }
