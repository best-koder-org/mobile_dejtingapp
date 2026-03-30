import 'package:flutter/material.dart';

import '../../flavors/flavor_config.dart';
import '../../models.dart';
import '../../services/voice_answer_service.dart';
import 'voice_answer_player_card.dart';

/// Blind discovery card for the Voice flavor.
///
/// Shows a silhouette avatar, name/age/city, and voice answer player cards
/// instead of photos. Matches the Stitch "Blind Discovery" screen design.
class VoiceDiscoveryCard extends StatefulWidget {
  final MatchCandidate candidate;
  final VoidCallback? onLike;
  final VoidCallback? onPass;
  final VoidCallback? onSuperLike;

  const VoiceDiscoveryCard({
    super.key,
    required this.candidate,
    this.onLike,
    this.onPass,
    this.onSuperLike,
  });

  @override
  State<VoiceDiscoveryCard> createState() => _VoiceDiscoveryCardState();
}

class _VoiceDiscoveryCardState extends State<VoiceDiscoveryCard> {
  List<VoiceAnswerPreview> _voiceAnswers = [];
  bool _isLoading = true;
  int _activeAnswerIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadVoiceAnswers();
  }

  @override
  void didUpdateWidget(VoiceDiscoveryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candidate.userId != widget.candidate.userId) {
      _loadVoiceAnswers();
    }
  }

  Future<void> _loadVoiceAnswers() async {
    setState(() {
      _isLoading = true;
      _activeAnswerIndex = -1;
    });

    final userId = int.tryParse(widget.candidate.userId);
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final answers = await VoiceAnswerService().getUserAnswers(userId);
    if (mounted) {
      setState(() {
        _voiceAnswers = answers;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              const SizedBox(height: 16),
              // Silhouette avatar
              _buildSilhouetteAvatar(context, primary),
              const SizedBox(height: 20),
              // Profile identity
              _buildProfileIdentity(context),
              const SizedBox(height: 8),
              // Interest tags
              if (widget.candidate.interestsOverlap.isNotEmpty)
                _buildInterestTags(context),
              const SizedBox(height: 32),
              // Voice answer cards
              _buildVoiceAnswerSection(context),
              const SizedBox(height: 16),
              // Bio section (if available)
              if (widget.candidate.bio != null && widget.candidate.bio!.isNotEmpty)
                _buildBioSection(context),
            ],
          ),
        ),
        // Action buttons
        _buildActionButtons(context, primary),
      ],
    );
  }

  Widget _buildSilhouetteAvatar(BuildContext context, Color primary) {
    final name = widget.candidate.displayName;
    return Center(
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary.withValues(alpha: 0.3),
              Theme.of(context).colorScheme.surface,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.15),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.person,
            size: 80,
            color: primary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileIdentity(BuildContext context) {
    final theme = Theme.of(context);
    final candidate = widget.candidate;

    return Column(
      children: [
        // Name, Age
        Text(
          '${candidate.displayName}, ${candidate.age}',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        if (candidate.city != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Text(
                candidate.city!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
        // Compatibility score
        if (FlavorConfig.current.featureFlags.showCompatibilityScores &&
            candidate.compatibility > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.whatshot, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  '${(candidate.compatibility * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInterestTags(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: widget.candidate.interestsOverlap.map((interest) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text(
              interest,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVoiceAnswerSection(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_voiceAnswers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.mic_off,
                size: 40,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 8),
              Text(
                'No voice answers yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'VOICE ANSWERS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
          ),
          // Grid of voice answer cards (up to 3 in a row)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _voiceAnswers.length >= 3 ? 3 : _voiceAnswers.length,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: _voiceAnswers.length.clamp(0, 6),
            itemBuilder: (context, index) {
              return VoiceAnswerPlayerCard(
                answer: _voiceAnswers[index],
                isActive: _activeAnswerIndex == index,
                onTap: () {
                  setState(() {
                    _activeAnswerIndex = _activeAnswerIndex == index ? -1 : index;
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ABOUT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.candidate.bio!,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Color primary) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor.withValues(alpha: 0.0),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pass button
                _buildCircleButton(
                  icon: Icons.close,
                  size: 56,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  borderColor: theme.dividerColor,
                  onTap: widget.onPass,
                ),
                const SizedBox(width: 24),
                // Like button (primary, larger)
                _buildCircleButton(
                  icon: Icons.favorite,
                  size: 72,
                  color: Colors.white,
                  backgroundColor: primary,
                  glowColor: primary.withValues(alpha: 0.4),
                  onTap: widget.onLike,
                ),
                const SizedBox(width: 24),
                // Superlike button
                _buildCircleButton(
                  icon: Icons.auto_awesome,
                  size: 56,
                  color: primary,
                  borderColor: primary.withValues(alpha: 0.3),
                  onTap: widget.onSuperLike,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              FlavorConfig.current.copy.discoverSubtitle,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required double size,
    required Color color,
    Color? backgroundColor,
    Color? borderColor,
    Color? glowColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? Colors.transparent,
          border: borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: glowColor != null
              ? [BoxShadow(color: glowColor, blurRadius: 20, spreadRadius: 2)]
              : null,
        ),
        child: Icon(icon, color: color, size: size * 0.4),
      ),
    );
  }
}
