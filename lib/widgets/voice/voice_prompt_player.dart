import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dejtingapp/services/voice_prompt_service.dart';
import 'package:dejtingapp/theme/app_theme.dart';

/// Reusable voice prompt player card.
///
/// Shows a "VOICE PROMPT" header, decorative waveform, and play/stop button.
/// Uses [VoicePromptService] singleton for authenticated audio streaming.
///
/// Usage:
/// ```dart
/// VoicePromptPlayer(
///   voicePromptUrl: candidate.voicePromptUrl!,
///   displayName: candidate.displayName,
/// );
/// ```
class VoicePromptPlayer extends StatefulWidget {
  /// URL to the voice prompt audio (will be fetched with auth headers).
  final String voicePromptUrl;

  /// Display name of the profile owner (for "Hear X's voice" subtitle).
  final String displayName;

  /// Optional callback when the user double-taps (like gesture).
  final VoidCallback? onDoubleTap;

  const VoicePromptPlayer({
    super.key,
    required this.voicePromptUrl,
    required this.displayName,
    this.onDoubleTap,
  });

  @override
  State<VoicePromptPlayer> createState() => _VoicePromptPlayerState();
}

class _VoicePromptPlayerState extends State<VoicePromptPlayer> {
  final VoicePromptService _service = VoicePromptService();
  bool _isPlaying = false;

  @override
  void dispose() {
    // Stop playback if this widget goes away
    if (_isPlaying) {
      _service.stopPlayback();
    }
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _service.stopPlayback();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      await _service.playFromUrl(widget.voicePromptUrl);
      if (mounted) setState(() => _isPlaying = true);
      // Listen for completion
      _service.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) setState(() => _isPlaying = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: widget.onDoubleTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.surfaceElevated, AppTheme.surfaceColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: mic icon + labels
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VOICE PROMPT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor.withValues(alpha: 0.8),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hear ${widget.displayName.split(' ').first}\'s voice',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Decorative waveform
            _buildWaveform(),
            const SizedBox(height: 16),

            // Play button row
            Row(
              children: [
                Material(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: _togglePlayback,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isPlaying ? 'Stop' : 'Play',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '0:15',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    const heights = [
      0.3, 0.5, 0.7, 0.4, 0.9, 0.6, 0.8, 0.5, 0.3, 0.7,
      0.95, 0.6, 0.4, 0.8, 0.5, 0.7, 0.3, 0.6, 0.9, 0.4,
      0.7, 0.5, 0.8, 0.3, 0.6, 0.9, 0.5, 0.7, 0.4, 0.3,
    ];
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(30, (i) {
          final h = heights[i % heights.length] * 36;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              height: h,
              decoration: BoxDecoration(
                color: _isPlaying
                    ? AppTheme.primaryColor.withValues(alpha: 0.7)
                    : AppTheme.primaryColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
