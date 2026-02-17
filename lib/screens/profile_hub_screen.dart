import 'package:flutter/material.dart';
import 'package:dejtingapp/theme/app_theme.dart';
import 'package:dejtingapp/services/api_service.dart' hide PhotoService;
import 'package:dejtingapp/services/verification_service.dart';
import 'package:dejtingapp/services/safety_service.dart';
import 'package:dejtingapp/services/photo_service.dart';
import 'package:dejtingapp/widgets/verification_badge.dart';
import 'package:dejtingapp/utils/profile_completion_calculator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'verification_selfie_screen.dart';
import 'settings_screen.dart';

/// DejTing profile hub — inspired by Hinge but branded for DejTing.
///
/// 3 tabs:  Get more  |  Safety  |  My DejTing
///
/// Features our own concepts:
///   • Spark ⚡ — a special like + message that stands out
///   • Spotlight 🔦 — get highlighted in the discover feed
///   • DejTing Plus — premium subscription tier
class ProfileHubScreen extends StatefulWidget {
  const ProfileHubScreen({super.key});

  @override
  State<ProfileHubScreen> createState() => _ProfileHubScreenState();
}

class _ProfileHubScreenState extends State<ProfileHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Profile data
  String _displayName = '';
  String? _primaryPhotoUrl;
  bool _isVerified = false;
  int _profileCompletion = 0;
  int _blockedCount = 0;
  Map<String, String>? _imageHeaders;

  // Spark / Spotlight balances (persisted later via backend)
  int _sparksRemaining = 1; // Free users get 1/week
  int _spotlightMinutes = 0;
  bool _isPlusSubscriber = false;

  // Services
  final _verificationService = VerificationService();
  final _photoService = PhotoService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final appState = AppState();
      final token = await appState.getOrRefreshAuthToken();
      final userId = int.tryParse(appState.userId ?? '');

      _displayName = appState.userProfile?['preferred_username'] as String? ?? appState.userProfile?['name'] as String? ?? 'Profile';

      if (token != null) {
        _imageHeaders = {'Authorization': 'Bearer $token'};

        // Load photos + calculate profile completion
        if (userId != null) {
          final summary = await _photoService.getUserPhotos(
            authToken: token,
            userId: userId,
          );
          if (summary != null && summary.photos.isNotEmpty) {
            final primaryPhoto = summary.photos.firstWhere(
              (p) => p.isPrimary,
              orElse: () => summary.photos.first,
            );
            _primaryPhotoUrl = primaryPhoto.urls.medium.isNotEmpty
                ? primaryPhoto.urls.medium
                : primaryPhoto.urls.thumbnail;

            // Profile completion based on photos available
            _profileCompletion = ProfileCompletionCalculator.calculateProfileCompletion(
              firstName: _displayName,
              lastName: '',
              bio: '', // We don't have bio cached here — profile editor owns it
              photoUrls: summary.photos.map((p) => p.urls.thumbnail).toList(),
              interests: [],
            );
          }
        }

        // Verification status
        final verStatus = await _verificationService.getStatus();
        _isVerified = verStatus?.isVerified ?? false;

        // Block count
        try {
          final blocked = await SafetyService.getBlockedUsers();
          _blockedCount = blocked.length;
        } catch (_) {
          _blockedCount = 0;
        }
      }
    } catch (e) {
      debugPrint('❌ ProfileHub: Failed to load data: $e');
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildProfileHeader(),

            // Tab Bar
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.dividerColor, width: 0.5),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Get more'),
                  Tab(text: 'Safety'),
                  Tab(text: 'My DejTing'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGetMoreTab(),
                  _buildSafetyTab(),
                  _buildMyDejTingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // Profile Header
  // ════════════════════════════════════════════════════════

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isVerified
                        ? AppTheme.secondaryColor.withValues(alpha: 0.5)
                        : AppTheme.dividerColor,
                    width: 3,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: ClipOval(
                    child: _primaryPhotoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: _primaryPhotoUrl!,
                            httpHeaders: _imageHeaders,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _photoPlaceholder(),
                            errorWidget: (_, __, ___) => _photoPlaceholder(),
                          )
                        : _photoPlaceholder(),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/profile').then(
                    (_) => _loadProfileData(),
                  ),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.dividerColor, width: 1),
                    ),
                    child: const Icon(Icons.edit, size: 16, color: AppTheme.textPrimary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _displayName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (_isVerified) ...[
                const SizedBox(width: 8),
                const VerificationBadge(isVerified: true, size: 24),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: AppTheme.surfaceElevated,
      child: const Icon(Icons.person, size: 48, color: AppTheme.textTertiary),
    );
  }

  // ════════════════════════════════════════════════════════
  // Tab 1: Get More
  // ════════════════════════════════════════════════════════

  Widget _buildGetMoreTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── DejTing Plus promo ──
        _buildPromoCard(
          title: 'DejTing Plus',
          subtitle: 'Unlimited Sparks, weekly Spotlight,\nand see who likes you first.',
          gradientColors: [AppTheme.secondaryColor, AppTheme.primaryColor],
          buttonText: _isPlusSubscriber ? 'Manage' : 'Upgrade',
          onPressed: () => _showPlusSheet(),
        ),

        const SizedBox(height: 16),

        // ── Spotlight card ──
        _buildFeatureCard(
          icon: Icons.flashlight_on,
          iconColor: AppTheme.warningColor,
          badgeCount: _spotlightMinutes > 0 ? _spotlightMinutes : null,
          badgeLabel: _spotlightMinutes > 0 ? '${_spotlightMinutes}m' : null,
          title: 'Spotlight',
          subtitle: 'Jump to the front — get seen by 10× more people for 30 min.',
          onTap: () => _showSpotlightSheet(),
        ),

        const SizedBox(height: 12),

        // ── Sparks card ──
        _buildFeatureCard(
          icon: Icons.bolt,
          iconColor: AppTheme.tealAccent,
          badgeCount: _sparksRemaining,
          title: 'Sparks',
          subtitle: 'Send a Spark with a message — 3× more likely to match.',
          onTap: () => _showSparksSheet(),
        ),

        const SizedBox(height: 12),

        // ── Profile Strength card ──
        _buildFeatureCard(
          icon: Icons.stars,
          iconColor: ProfileCompletionCalculator.getCompletionColor(_profileCompletion),
          title: 'Profile Strength',
          subtitle: ProfileCompletionCalculator.getMatchQualityBonus(_profileCompletion),
          trailing: _buildCompletionIndicator(),
          onTap: () => Navigator.pushNamed(context, '/profile').then(
            (_) => _loadProfileData(),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  // Tab 2: Safety
  // ════════════════════════════════════════════════════════

  Widget _buildSafetyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Selfie Verification
        _buildSafetyCard(
          icon: Icons.verified_user,
          iconColor: AppTheme.secondaryColor,
          isChecked: _isVerified,
          title: 'Selfie verification',
          subtitle: _isVerified ? "You're verified ✓" : 'Verify your identity',
          onTap: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const VerificationSelfieScreen()),
            );
            if (result == true) _loadProfileData();
          },
        ),

        const SizedBox(height: 12),

        // Comment filter
        _buildSafetyCard(
          icon: Icons.chat_bubble_outline,
          iconColor: AppTheme.secondaryColor,
          isChecked: true,
          title: 'Message filter',
          subtitle: 'Hiding messages with disrespectful language.',
          onTap: () => _showComingSoon('Message filter settings'),
        ),

        const SizedBox(height: 12),

        // Block list
        _buildSafetyCard(
          icon: Icons.block,
          iconColor: AppTheme.secondaryColor,
          isChecked: true,
          title: 'Block list',
          subtitle: '$_blockedCount contact${_blockedCount == 1 ? '' : 's'} blocked.',
          onTap: () => _showBlockListSheet(),
        ),

        const SizedBox(height: 32),

        // Safety resources header
        Text(
          'Safety resources',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildResourceButton(
                icon: Icons.phone_in_talk,
                label: 'Crisis hotlines',
                onTap: () => _launchUrl('https://www.iasp.info/resources/Crisis_Centres/'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildResourceButton(
                icon: Icons.shield_outlined,
                label: 'Safety tips',
                onTap: () => _launchUrl('https://www.staysafe.org/dating-safety-tips/'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  // Tab 3: My DejTing
  // ════════════════════════════════════════════════════════

  Widget _buildMyDejTingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Fresh Start card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 28,
                  color: AppTheme.tealAccent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Fresh start',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Update your prompts and photos\nto spark new conversations.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/profile').then(
                  (_) => _loadProfileData(),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.textPrimary),
                  foregroundColor: AppTheme.textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: const Text('Edit profile'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Dating tips
        _buildFeatureCard(
          icon: Icons.lightbulb_outline,
          iconColor: AppTheme.warningColor,
          title: 'Dating tips',
          subtitle: 'Expert-backed advice for better dates',
          onTap: () => _showComingSoon('Dating tips'),
        ),

        const SizedBox(height: 12),

        // Help centre
        _buildFeatureCard(
          icon: Icons.help_outline,
          iconColor: AppTheme.textSecondary,
          title: 'Help centre',
          subtitle: 'FAQs, safety and account support',
          onTap: () => _showComingSoon('Help centre'),
        ),

        const SizedBox(height: 12),

        // Settings
        _buildFeatureCard(
          icon: Icons.settings,
          iconColor: AppTheme.textSecondary,
          title: 'Settings',
          subtitle: 'Discovery, notifications, privacy',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),

        const SizedBox(height: 24),

        // Logout
        Center(
          child: TextButton(
            onPressed: _showLogoutDialog,
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Logout', style: TextStyle(fontSize: 16)),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  // Bottom Sheets — Spark / Spotlight / Plus
  // ════════════════════════════════════════════════════════

  void _showSparksSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _BottomSheetWrap(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 16),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.tealAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt, size: 36, color: AppTheme.tealAccent),
            ),
            const SizedBox(height: 16),
            Text(
              'Send a Spark ⚡',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'A Spark lets you send a like with a personal message — so they know you\'re serious. '
                'Profiles that receive a Spark are 3× more likely to match.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            // Balance
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Your Sparks', style: TextStyle(fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      const Icon(Icons.bolt, size: 20, color: AppTheme.tealAccent),
                      const SizedBox(width: 4),
                      Text(
                        '$_sparksRemaining',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.tealAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isPlusSubscriber
                  ? 'Plus subscribers get 5 Sparks per week.'
                  : 'Free: 1 Spark per week. Upgrade for 5.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (!_isPlusSubscriber)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showPlusSheet();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Get more Sparks'),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showSpotlightSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _BottomSheetWrap(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 16),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flashlight_on, size: 36, color: AppTheme.warningColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Spotlight 🔦',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Spotlight puts your profile at the top of Discover for 30 minutes. '
                'Get seen by up to 10× more people and land more matches.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            // How it works
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('How it works', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _spotlightStep('1', 'Activate Spotlight'),
                  const SizedBox(height: 8),
                  _spotlightStep('2', 'Your profile jumps to the top of Discover'),
                  const SizedBox(height: 8),
                  _spotlightStep('3', 'Enjoy 30 min of boosted visibility'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _spotlightMinutes > 0
                    ? null
                    : () {
                        setState(() => _spotlightMinutes = 30);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🔦 Spotlight activated! 30 min of boosted visibility.'),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningColor,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _spotlightMinutes > 0
                      ? 'Active — ${_spotlightMinutes}m remaining'
                      : _isPlusSubscriber
                          ? 'Activate Spotlight (1/week free)'
                          : 'Activate Spotlight',
                ),
              ),
            ),
            if (!_isPlusSubscriber) ...[
              const SizedBox(height: 8),
              Text(
                'Plus subscribers get 1 free Spotlight per week.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _spotlightStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.warningColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: AppTheme.warningColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  void _showPlusSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _BottomSheetWrap(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 8),
            // Gradient header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppTheme.secondaryColor, AppTheme.primaryColor],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'DejTing Plus',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The full DejTing experience',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Perks list
            _plusPerk(Icons.bolt, AppTheme.tealAccent, '5 Sparks per week', 'Free gets 1'),
            _plusPerk(Icons.flashlight_on, AppTheme.warningColor, '1 free Spotlight per week', '30 min boost'),
            _plusPerk(Icons.visibility, AppTheme.secondaryColor, 'See who likes you', 'Before matching'),
            _plusPerk(Icons.tune, AppTheme.primaryColor, 'Advanced filters', 'Height, lifestyle, more'),
            _plusPerk(Icons.refresh, AppTheme.tertiaryColor, 'Unlimited rewinds', 'Undo accidental skips'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showComingSoon('DejTing Plus subscriptions');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Coming soon', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _plusPerk(IconData icon, Color color, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // Block List Sheet
  // ════════════════════════════════════════════════════════

  void _showBlockListSheet() async {
    try {
      final blocked = await SafetyService.getBlockedUsers();
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              const _SheetHandle(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Block list', style: Theme.of(context).textTheme.titleLarge),
              ),
              const Divider(height: 1),
              Expanded(
                child: blocked.isEmpty
                    ? const Center(
                        child: Text(
                          'No blocked contacts',
                          style: TextStyle(color: AppTheme.textTertiary),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: blocked.length,
                        itemBuilder: (context, index) {
                          final user = blocked[index];
                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(
                              user['displayName'] ?? 'User ${user['blockedUserId']}',
                            ),
                            trailing: TextButton(
                              onPressed: () async {
                                final userId = user['blockedUserId']?.toString();
                                if (userId != null) {
                                  await SafetyService.unblockUser(userId);
                                  if (mounted) {
                                    Navigator.pop(context);
                                    _loadProfileData();
                                  }
                                }
                              },
                              child: const Text('Unblock'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load block list: $e')),
        );
      }
    }
  }

  // ════════════════════════════════════════════════════════
  // Shared Builders
  // ════════════════════════════════════════════════════════

  Widget _buildPromoCard({
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 12),
          Text(subtitle, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: gradientColors.last,
              minimumSize: const Size(160, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    int? badgeCount,
    String? badgeLabel,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration,
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                if (badgeCount != null || badgeLabel != null)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeLabel ?? '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyCard({
    required IconData icon,
    required Color iconColor,
    required bool isChecked,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration,
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                if (isChecked)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E88E5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 14, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: AppTheme.cardDecoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionIndicator() {
    final color = ProfileCompletionCalculator.getCompletionColor(_profileCompletion);
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: _profileCompletion / 100,
            strokeWidth: 3,
            backgroundColor: AppTheme.dividerColor,
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text(
            '$_profileCompletion%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // Dialogs / Helpers
  // ════════════════════════════════════════════════════════

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — coming soon!')),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ════════════════════════════════════════════════════════
// Shared bottom-sheet widgets
// ════════════════════════════════════════════════════════

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.dividerColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _BottomSheetWrap extends StatelessWidget {
  final Widget child;
  const _BottomSheetWrap({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: child,
    );
  }
}
