import 'package:flutter/material.dart';
import 'package:dejtingapp/l10n/generated/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dejtingapp/theme/app_theme.dart';
import 'package:dejtingapp/api_services.dart';
import 'package:dejtingapp/models.dart';
import 'package:dejtingapp/screens/profile_detail_screen.dart';

/// Hinge-style scrollable Discover screen
/// Shows one profile at a time as a vertically-scrollable card
/// with interleaved photos, prompts, and info sections.
/// Users can like specific content or skip the entire profile.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<MatchCandidate> _candidates = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _hasError = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadCandidates();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadCandidates() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final candidates = await matchmakingApi.getCandidates();
      setState(() {
        _candidates = candidates;
        _currentIndex = 0;
        _isLoading = false;
      });
      _fadeController.forward(from: 0);
    } catch (e) {
      debugPrint('Error loading candidates: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  MatchCandidate? get _currentCandidate =>
      _currentIndex < _candidates.length ? _candidates[_currentIndex] : null;

  void _skipProfile() {
    if (_currentIndex < _candidates.length - 1) {
      setState(() => _currentIndex++);
      _scrollController.jumpTo(0);
      _fadeController.forward(from: 0);
    } else {
      setState(() => _currentIndex = _candidates.length);
    }
  }

  void _likeProfile({String? likedContent}) {
    final candidate = _currentCandidate;
    if (candidate == null) return;

    debugPrint(
      '\u2764\uFE0F Liked profile ${candidate.userId}'
      '${likedContent != null ? " (content: $likedContent)" : ""}',
    );

    // TODO: Send like to backend via matchmakingApi.swipe()
    _skipProfile();
  }

  void _onLikeContent(String contentType, String contentValue) {
    _showLikeSheet(contentType, contentValue);
  }

  void _viewCandidateProfile(MatchCandidate candidate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(
          candidate: candidate,
          isMatched: false,
          onLike: () => _likeProfile(),
          onSkip: _skipProfile,
        ),
      ),
    );
  }

  void _showLikeSheet(String contentType, String value) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _LikeCommentSheet(
        contentType: contentType,
        contentPreview: value,
        onSend: (comment) {
          Navigator.pop(ctx);
          _likeProfile(likedContent: '$contentType: $value | comment: $comment');
        },
        onLikeOnly: () {
          Navigator.pop(ctx);
          _likeProfile(likedContent: '$contentType: $value');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(bottom: BorderSide(color: AppTheme.dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.discoverTitle,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (_candidates.isNotEmpty)
            Text(
              '${_currentIndex + 1}/${_candidates.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 22),
            onPressed: () {},
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primarySubtle,
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoadingState();
    if (_hasError) return _buildErrorState();
    final candidate = _currentCandidate;
    if (candidate == null) return _buildEmptyState();
    return _buildProfileView(candidate);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.findingPeopleNearYou),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.textTertiary),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.somethingWentWrong, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.checkConnectionRetry,
              style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCandidates,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context)!.tryAgainButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primarySubtle,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.explore_rounded, size: 48, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context)!.seenEveryone,
              style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.checkBackLater,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _loadCandidates,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context)!.refreshButton),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Scrollable Profile View (Hinge-style) ───────────
  Widget _buildProfileView(MatchCandidate candidate) {
    return FadeTransition(
      opacity: _fadeController,
      child: Stack(
        children: [
          ListView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              // Hero photo (first photo)
              _buildHeroPhoto(
                candidate.photoUrl ?? (candidate.photoUrls.isNotEmpty ? candidate.photoUrls[0] : null),
                candidate.displayName,
                candidate.age,
                candidate.city,
                candidate.isVerified,
              ),
              // Vitals bar (occupation, height, education, etc.)
              _buildVitalsBar(candidate),
              // All photos, prompts, voice interleaved
              ..._buildInterleavedContent(candidate),
              const SizedBox(height: 24),
            ],
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _buildActionBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPhoto(String? photoUrl, String name, int age, String? city, bool isVerified) {
    return GestureDetector(
      onTap: () {
        final candidate = _currentCandidate;
        if (candidate != null) _viewCandidateProfile(candidate);
      },
      onDoubleTap: () => _onLikeContent('photo', photoUrl ?? 'main'),
      child: Container(
        height: 480,
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          color: AppTheme.surfaceDark,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photoUrl != null && photoUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppTheme.surfaceDark,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    ),
                  ),
                  errorWidget: (_, __, ___) => _buildPhotoPlaceholder(name),
                )
              else
                _buildPhotoPlaceholder(name),

              // Gradient overlay
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppTheme.radiusXl),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // Name / Age / Verified overlay
              Positioned(
                bottom: 20, left: 20, right: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white, fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$age',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 24, fontWeight: FontWeight.w300,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 14),
                          ),
                        ],
                      ],
                    ),
                    if (city != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14,
                            color: Colors.white.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Text(city, style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          )),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Like button on photo
              Positioned(
                bottom: 16, right: 16,
                child: _buildContentLikeButton('photo', photoUrl ?? 'main'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder(String name) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.darkGradient,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white, fontSize: 72, fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }

  Widget _buildVitalsBar(MatchCandidate c) {
    final vitals = <Widget>[];

    if (c.occupation != null && c.occupation!.isNotEmpty) {
      vitals.add(_buildVitalChip(Icons.work_outline_rounded, c.occupation!));
    }
    if (c.height != null && c.height! > 0) {
      vitals.add(_buildVitalChip(Icons.straighten_rounded, '${c.height} cm'));
    }
    if (c.education != null && c.education!.isNotEmpty) {
      vitals.add(_buildVitalChip(Icons.school_outlined, c.education!));
    }
    if (c.distanceKm != null) {
      vitals.add(_buildVitalChip(Icons.near_me_rounded, '${c.distanceKm!.toStringAsFixed(0)} km'));
    }

    if (vitals.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Wrap(spacing: 8, runSpacing: 8, children: vitals),
    );
  }

  Widget _buildVitalChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  /// Build interleaved content: Photo → Prompt → Photo → Prompt → Voice → Photo → Interests
  List<Widget> _buildInterleavedContent(MatchCandidate candidate) {
    final widgets = <Widget>[];
    final photos = candidate.photoUrls;
    final prompts = candidate.prompts;

    int photoIdx = 1; // hero is index 0, start from 1
    int promptIdx = 0;
    bool voiceInserted = false;

    // Bio card first if present (always show bio)
    if (candidate.bio != null && candidate.bio!.isNotEmpty) {
      widgets.add(_buildPromptCard('About me', candidate.bio!));
    }

    // Interleave remaining photos and API prompts
    while (photoIdx < photos.length || promptIdx < prompts.length) {
      // Add a prompt
      if (promptIdx < prompts.length) {
        widgets.add(_buildPromptCard(
          prompts[promptIdx].question,
          prompts[promptIdx].answer,
        ));
        promptIdx++;
      }

      // Add a photo
      if (photoIdx < photos.length) {
        widgets.add(_buildPhotoCard(photos[photoIdx], photoIdx + 1, photos.length));
        photoIdx++;
      }

      // Insert voice prompt after the second content pair
      if (!voiceInserted && candidate.voicePromptUrl != null && widgets.length >= 3) {
        widgets.add(_buildVoicePromptCard(candidate.voicePromptUrl!, candidate.displayName));
        voiceInserted = true;
      }
    }

    // Voice prompt at end if not yet inserted
    if (!voiceInserted && candidate.voicePromptUrl != null) {
      widgets.add(_buildVoicePromptCard(candidate.voicePromptUrl!, candidate.displayName));
    }

    // Interests section
    if (candidate.interestsOverlap.isNotEmpty) {
      widgets.add(_buildInterestsSection(candidate.interestsOverlap));
    }

    return widgets;
  }

  Widget _buildPromptCard(String question, String answer) {
    return GestureDetector(
      onDoubleTap: () => _onLikeContent('prompt', answer),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.dividerColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.toUpperCase(),
              style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor, letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              answer,
              style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary, height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomRight,
              child: _buildContentLikeButton('prompt', answer),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(String photoUrl, int photoNumber, int totalPhotos) {
    return GestureDetector(
      onDoubleTap: () => _onLikeContent('photo', photoUrl),
      child: Container(
        height: 400,
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          color: AppTheme.surfaceDark,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppTheme.surfaceDark,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppTheme.surfaceDark,
                  child: const Icon(Icons.image_outlined, color: AppTheme.textTertiary, size: 48),
                ),
              ),
              // Photo counter badge
              Positioned(
                top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$photoNumber/$totalPhotos',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Positioned(
                bottom: 12, right: 12,
                child: _buildContentLikeButton('photo', photoUrl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoicePromptCard(String voiceUrl, String name) {
    return GestureDetector(
      onDoubleTap: () => _onLikeContent('voice', voiceUrl),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
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
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor.withValues(alpha: 0.8),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hear ${name.split(' ').first}\'s voice',
                        style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Waveform visualization (decorative)
            _buildWaveformVisual(),
            const SizedBox(height: 16),
            Row(
              children: [
                // Play button
                Material(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: () {
                      // TODO: Play voice prompt audio
                      debugPrint('Play voice prompt: $voiceUrl');
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 6),
                          Text('Play', style: TextStyle(
                            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '0:15',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary.withValues(alpha: 0.7)),
                ),
                const Spacer(),
                _buildContentLikeButton('voice', voiceUrl),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveformVisual() {
    // Decorative waveform bars
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(30, (i) {
          // Create a natural-looking waveform pattern
          final heights = [0.3, 0.5, 0.7, 0.4, 0.9, 0.6, 0.8, 0.5, 0.3, 0.7,
            0.95, 0.6, 0.4, 0.8, 0.5, 0.7, 0.3, 0.6, 0.9, 0.4,
            0.7, 0.5, 0.8, 0.3, 0.6, 0.9, 0.5, 0.7, 0.4, 0.3];
          final h = heights[i % heights.length] * 36;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              height: h,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInterestsSection(List<String> interests) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.dividerColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INTERESTS',
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor, letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: interests.map((interest) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primarySubtle,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                interest,
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: AppTheme.primaryDark,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContentLikeButton(String type, String value) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onLikeContent(type, value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite_border_rounded,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
      ),
    );
  }

  // ─── Sticky Action Bar ────────────────────────────────
  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.scaffoldLight.withValues(alpha: 0),
            AppTheme.scaffoldLight,
            AppTheme.scaffoldLight,
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.close_rounded,
            color: AppTheme.textTertiary,
            bgColor: AppTheme.surfaceColor,
            size: 56, iconSize: 28,
            onTap: _skipProfile,
            label: AppLocalizations.of(context)!.skipAction,
          ),
          const SizedBox(width: 16),
          _buildActionButton(
            icon: Icons.favorite_rounded,
            color: Colors.white,
            bgColor: AppTheme.primaryColor,
            size: 64, iconSize: 32,
            onTap: () => _likeProfile(),
            label: AppLocalizations.of(context)!.likeButton,
            elevated: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required double size,
    required double iconSize,
    required VoidCallback onTap,
    required String label,
    bool elevated = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size, height: size,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: elevated ? null : Border.all(color: AppTheme.dividerColor, width: 1.5),
              boxShadow: elevated ? [
                BoxShadow(
                  color: bgColor.withValues(alpha: 0.4),
                  blurRadius: 16, offset: const Offset(0, 4),
                ),
              ] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8, offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(
          fontSize: 11, color: AppTheme.textTertiary,
          fontWeight: FontWeight.w500,
        )),
      ],
    );
  }
}

// Like + Comment Bottom Sheet (Hinge-style)
class _LikeCommentSheet extends StatefulWidget {
  final String contentType;
  final String contentPreview;
  final Function(String comment) onSend;
  final VoidCallback onLikeOnly;

  const _LikeCommentSheet({
    required this.contentType,
    required this.contentPreview,
    required this.onSend,
    required this.onLikeOnly,
  });

  @override
  State<_LikeCommentSheet> createState() => _LikeCommentSheetState();
}

class _LikeCommentSheetState extends State<_LikeCommentSheet> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _hasText = _controller.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Add a comment?',
            style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Stand out by telling them why you liked this',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Say something nice...',
              counterStyle: const TextStyle(color: AppTheme.textTertiary),
              filled: true,
              fillColor: AppTheme.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onLikeOnly,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_rounded, size: 18, color: AppTheme.primaryColor),
                      SizedBox(width: 6),
                      Text('Like only'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _hasText ? () => widget.onSend(_controller.text.trim()) : null,
                  child: Text(AppLocalizations.of(context)!.sendWithComment),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
