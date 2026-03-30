import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dejtingapp/services/voice_answer_service.dart';
import 'package:dejtingapp/services/voice_prompt_service.dart';
import 'package:dejtingapp/flavors/flavor_config.dart';

/// Voice Onboarding Screen — record answers to 3 voice questions.
///
/// Flow: Load questions → show question 1 → record → upload → question 2 → …
/// After all required answers are uploaded, navigate to next onboarding step.
///
/// Reuses VoicePromptService for recording (AAC, 3-30s).
class VoiceOnboardingScreen extends StatefulWidget {
  const VoiceOnboardingScreen({super.key});

  @override
  State<VoiceOnboardingScreen> createState() => _VoiceOnboardingScreenState();
}

class _VoiceOnboardingScreenState extends State<VoiceOnboardingScreen>
    with SingleTickerProviderStateMixin {
  final VoiceAnswerService _answerService = VoiceAnswerService();
  final VoicePromptService _recorder = VoicePromptService();

  // State
  List<VoiceQuestion> _questions = [];
  int _currentIndex = 0;
  _Phase _phase = _Phase.loading;
  int _secondsElapsed = 0;
  Timer? _timer;
  String? _errorMessage;

  // Animation for pulsing mic
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int get _requiredCount => FlavorConfig.current.featureFlags.voiceAnswersRequired;

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
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final questions = await _answerService.getQuestions(
      flavorId: FlavorConfig.current.flavorId,
    );
    if (!mounted) return;
    if (questions.isEmpty) {
      setState(() {
        _phase = _Phase.error;
        _errorMessage = 'Could not load questions. Please try again.';
      });
      return;
    }
    // Take only the required number of questions
    setState(() {
      _questions = questions.take(_requiredCount).toList();
      _phase = _Phase.idle;
    });
  }

  // ──────────────── RECORDING ────────────────

  Future<void> _startRecording() async {
    final ok = await _recorder.startRecording();
    if (!ok) {
      setState(() => _errorMessage = 'Microphone access needed. Check your settings.');
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

  Future<void> _stopAndUpload() async {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    if (_secondsElapsed < VoicePromptService.minDurationSeconds) {
      await _recorder.cancelRecording();
      setState(() {
        _phase = _Phase.idle;
        _errorMessage = 'Too short — record at least ${VoicePromptService.minDurationSeconds} seconds';
      });
      return;
    }

    final path = await _recorder.stopRecording();
    if (path == null) {
      setState(() {
        _phase = _Phase.idle;
        _errorMessage = 'Recording failed. Please try again.';
      });
      return;
    }

    setState(() => _phase = _Phase.uploading);

    final question = _questions[_currentIndex];
    final answerId = await _answerService.uploadAnswer(
      questionId: question.id,
      filePath: path,
      durationSeconds: _secondsElapsed.toDouble(),
    );

    if (!mounted) return;

    if (answerId != null) {
      // Move to next question or finish
      if (_currentIndex + 1 < _questions.length) {
        setState(() {
          _currentIndex++;
          _phase = _Phase.idle;
          _secondsElapsed = 0;
        });
      } else {
        // All done — pop with success
        Navigator.pop(context, true);
      }
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
    await _recorder.cancelRecording();
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colors.onSurface),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          'Voice Intro',
          style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _phase == _Phase.loading
            ? const Center(child: CircularProgressIndicator())
            : _phase == _Phase.error
                ? _buildError()
                : _buildContent(theme, colors),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_errorMessage ?? 'Something went wrong',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() => _phase = _Phase.loading);
              _loadQuestions();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colors) {
    final question = _questions[_currentIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Progress indicator (1/3, 2/3, 3/3)
          _buildProgress(colors),
          const SizedBox(height: 32),

          // Question text
          Text(
            question.questionText,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Instruction
          Text(
            _phase == _Phase.uploading
                ? 'Saving…'
                : _phase == _Phase.recording
                    ? 'Recording — tap to stop'
                    : 'Tap the mic and answer in your own voice',
            style: TextStyle(
              fontSize: 15,
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          // Timer
          Text(
            _formatTime(_secondsElapsed),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w300,
              color: _phase == _Phase.recording ? colors.primary : colors.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),

          // Duration bar
          if (_phase == _Phase.recording)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: LinearProgressIndicator(
                value: _secondsElapsed / VoicePromptService.maxDurationSeconds,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(colors.primary),
              ),
            ),
          const SizedBox(height: 8),

          // Min duration hint
          if (_phase == _Phase.recording && _secondsElapsed < VoicePromptService.minDurationSeconds)
            Text(
              'Min ${VoicePromptService.minDurationSeconds}s',
              style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.4)),
            ),

          const SizedBox(height: 32),

          // Mic button
          _buildMicButton(colors),

          const SizedBox(height: 16),

          // Error message
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: colors.error, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildProgress(ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_questions.length, (i) {
        final isCompleted = i < _currentIndex;
        final isCurrent = i == _currentIndex;
        return Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isCompleted
                ? colors.primary
                : isCurrent
                    ? colors.primary.withValues(alpha: 0.5)
                    : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildMicButton(ColorScheme colors) {
    if (_phase == _Phase.uploading) {
      return SizedBox(
        width: 88,
        height: 88,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: colors.primary,
        ),
      );
    }

    return GestureDetector(
      onTap: _phase == _Phase.recording ? _stopAndUpload : _startRecording,
      onLongPress: _phase == _Phase.recording ? _cancelRecording : null,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = _phase == _Phase.recording ? _pulseAnimation.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _phase == _Phase.recording
                    ? colors.error
                    : colors.primary,
                boxShadow: [
                  BoxShadow(
                    color: (_phase == _Phase.recording
                            ? colors.error
                            : colors.primary)
                        .withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                _phase == _Phase.recording ? Icons.stop_rounded : Icons.mic,
                size: 40,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _Phase { loading, idle, recording, uploading, error }
