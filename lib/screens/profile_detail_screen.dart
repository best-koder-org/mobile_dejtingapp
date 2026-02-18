import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dejtingapp/theme/app_theme.dart';
import 'package:dejtingapp/models.dart';
import 'package:dejtingapp/widgets/voice/voice_prompt_player.dart';

/// Full-profile detail screen — Hinge-style scrollable view.
///
/// Accepts either a [MatchCandidate] (from Discover) or a [UserProfile]
/// (from Matches / Profile Hub) and renders the complete profile with
/// swipeable photo gallery, vitals, bio, prompts, interests, and lifestyle.
class ProfileDetailScreen extends StatefulWidget {
  /// Construct from a MatchCandidate (Discover tap).
  final MatchCandidate? candidate;

  /// Construct from a UserProfile (Matches / Profile tap).
  final UserProfile? profile;

  /// Whether this user is already matched with the viewer.
  final bool isMatched;

  /// Callback when the user taps "Like" (only shown if not already matched).
  final VoidCallback? onLike;

  /// Callback when the user taps "Skip" (only shown if not already matched).
  final VoidCallback? onSkip;

  /// Callback when the user taps "Message" (only shown if already matched).
  final VoidCallback? onMessage;

  const ProfileDetailScreen({
    super.key,
    this.candidate,
    this.profile,
    this.isMatched = false,
    this.onLike,
    this.onSkip,
    this.onMessage,
  }) : assert(candidate != null || profile != null,
             'Either candidate or profile must be provided');

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  late final PageController _photoPageController;
  int _currentPhotoIndex = 0;

  // ─── Derived accessors ──────────────────────────────
  String get _displayName =>
      widget.candidate?.displayName ??
      widget.profile?.fullName ??
      'Unknown';

  int get _age =>
      widget.candidate?.age ??
      widget.profile?.age ??
      0;

  String? get _city =>
      widget.candidate?.city ??
      widget.profile?.city;

  bool get _isVerified =>
      widget.candidate?.isVerified ??
      widget.profile?.isVerified ??
      false;

  String? get _bio =>
      widget.candidate?.bio ??
      widget.profile?.bio;

  String? get _occupation =>
      widget.candidate?.occupation ??
      widget.profile?.occupation;

  int? get _height =>
      widget.candidate?.height ??
      widget.profile?.height;

  String? get _education =>
      widget.candidate?.education ??
      widget.profile?.education;

  double? get _distanceKm => widget.candidate?.distanceKm;

  List<String> get _photoUrls {
    if (widget.candidate != null) {
      final urls = <String>[];
      if (widget.candidate!.photoUrl != null) urls.add(widget.candidate!.photoUrl!);
      for (final url in widget.candidate!.photoUrls) {
        if (!urls.contains(url)) urls.add(url);
      }
      return urls;
    }
    return widget.profile?.photoUrls ?? [];
  }

  List<PromptAnswer> get _prompts =>
      widget.candidate?.prompts ?? [];

  List<String> get _interests {
    if (widget.candidate != null) return widget.candidate!.interestsOverlap;
    return widget.profile?.interests ?? [];
  }

  String? get _gender =>
      widget.candidate?.gender ??
      widget.profile?.gender;

  // UserProfile-only fields
  String? get _relationshipGoals => widget.profile?.relationshipGoals;
  String? get _drinking => widget.profile?.drinking;
  String? get _smoking => widget.profile?.smoking;
  String? get _workout => widget.profile?.workout;
  List<String> get _languages => widget.profile?.languages ?? [];

  String? get _voicePromptUrl =>
      widget.candidate?.voicePromptUrl ??
      widget.profile?.voicePromptUrl;

  double? get _compatibility => widget.candidate?.compatibility;

  @override
  void initState() {
    super.initState();
    _photoPageController = PageController();
  }

  @override
  void dispose() {
    _photoPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ─── Photo gallery as SliverAppBar ────────
              _buildPhotoGalleryAppBar(),
              // ─── Profile content ──────────────────────
              SliverToBoxAdapter(child: _buildProfileContent()),
              // ─── Bottom padding for action bar ────────
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          // ─── Floating action bar ───────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _buildActionBar(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  PHOTO GALLERY (SliverAppBar with PageView)
  // ═══════════════════════════════════════════════════════
  Widget _buildPhotoGalleryAppBar() {
    final photos = _photoUrls;
    final hasPhotos = photos.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 520,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.surfaceColor,
      leading: _buildBackButton(),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: _showReportSheet,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: hasPhotos
            ? _buildPhotoPageView(photos)
            : _buildPhotoPlaceholder(),
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildPhotoPageView(List<String> photos) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _photoPageController,
          itemCount: photos.length,
          onPageChanged: (index) => setState(() => _currentPhotoIndex = index),
          itemBuilder: (context, index) {
            return CachedNetworkImage(
              imageUrl: photos[index],
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppTheme.surfaceDark,
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
              ),
              errorWidget: (_, __, ___) => _buildPhotoPlaceholder(),
            );
          },
        ),

        // Photo indicator dots
        if (photos.length > 1)
          Positioned(
            top: MediaQuery.of(context).padding.top + 56,
            left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(photos.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentPhotoIndex ? 24 : 8,
                  height: 4,
                  decoration: BoxDecoration(
                    color: i == _currentPhotoIndex
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),

        // Gradient overlay at bottom
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
        ),

        // Name / Age / Verified / City overlay
        Positioned(
          bottom: 24, left: 20, right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      _displayName,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_age > 0) ...[
                    const SizedBox(width: 10),
                    Text(
                      '$_age',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 26, fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                  if (_isVerified) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                    ),
                  ],
                ],
              ),
              if (_city != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16,
                      color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 4),
                    Text(_city!, style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 15,
                    )),
                    if (_distanceKm != null) ...[
                      const SizedBox(width: 8),
                      Text('· ${AppLocalizations.of(context).kmAway(_distanceKm!.round())}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        )),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
      child: Center(
        child: Text(
          _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white, fontSize: 80, fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  PROFILE CONTENT
  // ═══════════════════════════════════════════════════════
  Widget _buildProfileContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compatibility badge (if available)
        if (_compatibility != null) _buildCompatibilityBadge(),

        // Vitals bar
        _buildVitalsSection(),

        // Bio
        if (_bio != null && _bio!.isNotEmpty)
          _buildSectionCard(
            icon: Icons.person_outline_rounded,
            label: AppLocalizations.of(context).aboutMeLabel,
            child: Text(
              _bio!,
              style: const TextStyle(
                fontSize: 17, color: AppTheme.textPrimary, height: 1.5,
              ),
            ),
          ),

        // Voice Prompt
        if (_voicePromptUrl != null)
          VoicePromptPlayer(
            voicePromptUrl: _voicePromptUrl!,
            displayName: _displayName,
          ),

        // Prompts
        ..._prompts.map((p) => _buildPromptCard(p.question, p.answer)),

        // Interests
        if (_interests.isNotEmpty) _buildInterestsSection(),

        // Lifestyle details (UserProfile only)
        if (_hasLifestyleData) _buildLifestyleSection(),

        // Languages
        if (_languages.isNotEmpty) _buildLanguagesSection(),

        const SizedBox(height: 16),
      ],
    );
  }

  // ─── Compatibility Badge ──────────────────────────────
  Widget _buildCompatibilityBadge() {
    final pct = (_compatibility! * 100).round();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(
            AppLocalizations.of(context).percentCompatible(pct),
            style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            AppLocalizations.of(context).basedOnPreferences,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8), fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Vitals ───────────────────────────────────────────
  Widget _buildVitalsSection() {
    final chips = <_VitalData>[];

    if (_occupation != null && _occupation!.isNotEmpty) {
      chips.add(_VitalData(Icons.work_outline_rounded, _occupation!));
    }
    if (_height != null && _height! > 0) {
      chips.add(_VitalData(Icons.straighten_rounded, '$_height cm'));
    }
    if (_education != null && _education!.isNotEmpty) {
      chips.add(_VitalData(Icons.school_outlined, _education!));
    }
    if (_gender != null && _gender!.isNotEmpty) {
      chips.add(_VitalData(Icons.person_outline, _gender!));
    }
    if (_relationshipGoals != null && _relationshipGoals!.isNotEmpty) {
      chips.add(_VitalData(Icons.favorite_border_rounded, _relationshipGoals!));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: chips.map((v) => _buildVitalChip(v.icon, v.label)).toList(),
      ),
    );
  }

  Widget _buildVitalChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(
            fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500,
          )),
        ],
      ),
    );
  }

  // ─── Section Card ─────────────────────────────────────
  Widget _buildSectionCard({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor, letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ─── Prompt Card ──────────────────────────────────────
  Widget _buildPromptCard(String question, String answer) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
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
          const SizedBox(height: 12),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary, height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Interests ────────────────────────────────────────
  Widget _buildInterestsSection() {
    return _buildSectionCard(
      icon: Icons.interests_rounded,
      label: AppLocalizations.of(context).interestsLabel,
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: _interests.map((interest) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primarySubtle,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              interest,
              style: const TextStyle(
                fontSize: 14, color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Lifestyle ────────────────────────────────────────
  bool get _hasLifestyleData =>
      _drinking != null || _smoking != null || _workout != null;

  Widget _buildLifestyleSection() {
    return _buildSectionCard(
      icon: Icons.spa_rounded,
      label: AppLocalizations.of(context).lifestyleLabel,
      child: Column(
        children: [
          if (_drinking != null)
            _buildLifestyleRow(Icons.local_bar_rounded, AppLocalizations.of(context).drinkingLabel, _drinking!),
          if (_smoking != null)
            _buildLifestyleRow(Icons.smoking_rooms_rounded, AppLocalizations.of(context).smokingLabel, _smoking!),
          if (_workout != null)
            _buildLifestyleRow(Icons.fitness_center_rounded, AppLocalizations.of(context).workoutLabel, _workout!),
        ],
      ),
    );
  }

  Widget _buildLifestyleRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(
            fontSize: 14, color: AppTheme.textSecondary,
          )),
          const Spacer(),
          Text(value, style: const TextStyle(
            fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500,
          )),
        ],
      ),
    );
  }

  // ─── Languages ────────────────────────────────────────
  Widget _buildLanguagesSection() {
    return _buildSectionCard(
      icon: Icons.translate_rounded,
      label: AppLocalizations.of(context).languagesLabel,
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: _languages.map((lang) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Text(
              lang,
              style: const TextStyle(
                fontSize: 14, color: AppTheme.textPrimary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  ACTION BAR
  // ═══════════════════════════════════════════════════════
  Widget _buildActionBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20, 16, 20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.scaffoldDark.withValues(alpha: 0.0),
            AppTheme.scaffoldDark.withValues(alpha: 0.8),
            AppTheme.scaffoldDark,
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: widget.isMatched
          ? _buildMatchedActions()
          : _buildDiscoverActions(),
    );
  }

  Widget _buildDiscoverActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Skip button
        _buildCircleAction(
          icon: Icons.close_rounded,
          color: AppTheme.textTertiary,
          bgColor: AppTheme.surfaceColor,
          size: 56,
          onTap: () {
            widget.onSkip?.call();
            Navigator.pop(context);
          },
        ),
        // Like button
        _buildCircleAction(
          icon: Icons.favorite_rounded,
          color: Colors.white,
          bgColor: AppTheme.primaryColor,
          size: 64,
          onTap: () {
            widget.onLike?.call();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _buildMatchedActions() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          widget.onMessage?.call();
          Navigator.pop(context);
        },
        icon: const Icon(Icons.chat_bubble_rounded),
        label: Text(AppLocalizations.of(context).sendAMessage),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleAction({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.dividerColor, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }

  // ─── Report / Block Sheet ─────────────────────────────
  void _showReportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _displayName,
                  style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSheetOption(
                  icon: Icons.flag_outlined,
                  label: AppLocalizations.of(context).reportProfile,
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context).reportSubmitted)),
                    );
                  },
                ),
                _buildSheetOption(
                  icon: Icons.block_rounded,
                  label: AppLocalizations.of(context).blockUser,
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context).userHasBeenBlocked(_displayName))),
                    );
                  },
                  isDestructive: true,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(context).cancelButton),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppTheme.errorColor : AppTheme.textSecondary),
      title: Text(label, style: TextStyle(
        color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimary,
        fontWeight: FontWeight.w500,
      )),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}

// ─── Helper data class ────────────────────────────────
class _VitalData {
  final IconData icon;
  final String label;
  const _VitalData(this.icon, this.label);
}
