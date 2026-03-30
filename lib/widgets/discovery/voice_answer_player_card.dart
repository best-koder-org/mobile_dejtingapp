import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../services/api_service.dart';
import '../../services/voice_answer_service.dart';

/// Compact voice answer player card for blind discovery.
///
/// Shows question label, waveform bars, duration, and play/pause toggle.
/// Uses [just_audio] for playback.
class VoiceAnswerPlayerCard extends StatefulWidget {
  final VoiceAnswerPreview answer;
  final bool isActive;
  final VoidCallback? onTap;

  const VoiceAnswerPlayerCard({
    super.key,
    required this.answer,
    this.isActive = false,
    this.onTap,
  });

  @override
  State<VoiceAnswerPlayerCard> createState() => _VoiceAnswerPlayerCardState();
}

class _VoiceAnswerPlayerCardState extends State<VoiceAnswerPlayerCard> {
  AudioPlayer? _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  List<double> _waveformBars = [];

  @override
  void initState() {
    super.initState();
    // Generate pseudo-random waveform based on answer id for consistent look
    final rng = Random(widget.answer.id);
    _waveformBars = List.generate(12, (_) => 0.2 + rng.nextDouble() * 0.8);
    _duration = Duration(
      milliseconds: (widget.answer.durationSeconds * 1000).round(),
    );
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player?.pause();
      setState(() => _isPlaying = false);
      return;
    }

    if (_player == null) {
      _player = AudioPlayer();

      // Build authenticated URL
      final token = await AppState().getOrRefreshAuthToken();
      final url = VoiceAnswerService().audioUrl(widget.answer.id);

      try {
        await _player!.setAudioSource(
          AudioSource.uri(
            Uri.parse(url),
            headers: token != null ? {'Authorization': 'Bearer $token'} : null,
          ),
        );
      } catch (e) {
        debugPrint('VoiceAnswerPlayerCard: failed to load audio: $e');
        return;
      }

      _player!.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });

      _player!.durationStream.listen((dur) {
        if (dur != null && mounted) setState(() => _duration = dur);
      });

      _player!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() => _isPlaying = state.playing);
          if (state.processingState == ProcessingState.completed) {
            _player?.seek(Duration.zero);
            _player?.pause();
            setState(() {
              _isPlaying = false;
              _position = Duration.zero;
            });
          }
        }
      });
    }

    await _player?.play();
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  double get _progress =>
      _duration.inMilliseconds > 0
          ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
          : 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final isActive = widget.isActive || _isPlaying;

    // Short label from question text (first word or two)
    final label = _shortLabel(widget.answer.questionText);

    return GestureDetector(
      onTap: () {
        widget.onTap?.call();
        _togglePlayback();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? primary.withValues(alpha: 0.1) : surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? primary.withValues(alpha: 0.3) : theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Question label
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: primary.withValues(alpha: isActive ? 1.0 : 0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Waveform bars
            SizedBox(
              height: 24,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(_waveformBars.length, (i) {
                  final barProgress = i / _waveformBars.length;
                  final isPlayed = barProgress <= _progress;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: _waveformBars[i] * 24,
                        decoration: BoxDecoration(
                          color: isPlayed || isActive
                              ? primary
                              : primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            // Duration + play icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isPlaying ? _formatDuration(_position) : _formatDuration(_duration),
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 16,
                  color: primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Extract a short label from the question text.
  /// Takes first meaningful word (skipping common starters).
  String _shortLabel(String text) {
    final words = text.split(' ');
    if (words.length <= 2) return text;

    // Skip common Swedish question starters
    final skipWords = {'vad', 'berätta', 'hur', 'vilken', 'om', 'är', 'din', 'ditt', 'det', 'du'};
    for (final w in words) {
      final lower = w.toLowerCase().replaceAll(RegExp(r'[^a-öA-Ö]'), '');
      if (lower.isNotEmpty && !skipWords.contains(lower)) {
        return lower.length > 12 ? lower.substring(0, 12) : lower;
      }
    }
    return words.first;
  }
}
