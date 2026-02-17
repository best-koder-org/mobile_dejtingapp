import 'package:flutter/material.dart';
import 'package:dejtingapp/theme/app_theme.dart';
import 'package:dejtingapp/services/api_service.dart';
import 'package:dejtingapp/services/verification_service.dart';
import 'package:dejtingapp/services/safety_service.dart';
import 'package:dejtingapp/services/photo_service.dart';
import 'package:dejtingapp/widgets/verification_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'verification_selfie_screen.dart';
import 'settings_screen.dart';

/// Hinge-style profile hub with 3 tabs:
///   Get more  |  Safety  |  My DejTing
/// Circular profile photo header with name + verified badge.
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
  bool _isLoading = true;
  Map<String, String>? _imageHeaders;

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

      // Load name from app state or session
      _displayName = appState.displayName ?? 'Profile';

      if (token != null) {
        _imageHeaders = {'Authorization': 'Bearer $token'};

        // Load primary photo
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
          }
        }

        // Load verification status
        final verStatus = await _verificationService.getStatus();
        _isVerified = verStatus?.isVerified ?? false;

        // Load blocked users count
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ─── Profile Header (circular photo + name + badge) ───
            _buildProfileHeader(),

            // ─── Tab Bar ───
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

            // ─── Tab Content ───
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
  // Profile Header — Hinge style
  // ════════════════════════════════════════════════════════
  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Column(
        children: [
          // Circular photo with edit button
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring (gradient or solid)
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
                            placeholder: (_, __) => Container(
                              color: AppTheme.surfaceElevated,
                              child: const Icon(
                                Icons.person,
                                size: 48,
                                color: AppTheme.textTertiary,
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppTheme.surfaceElevated,
                              child: const Icon(
                                Icons.person,
                                size: 48,
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          )
                        : Container(
                            color: AppTheme.surfaceElevated,
                            child: const Icon(
                              Icons.person,
                              size: 48,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                  ),
                ),
              ),
              // Edit icon (top-right)
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
                      border: Border.all(
                        color: AppTheme.dividerColor,
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Name + verified badge
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

  // ════════════════════════════════════════════════════════
  // Tab 1: Get More (upgrades, boosts, premium features)
  // ════════════════════════════════════════════════════════
  Widget _buildGetMoreTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Premium upgrade card
        _buildPromoCard(
          title: 'DejTing Premium',
          subtitle: 'Get noticed sooner and go on\n3x as many dates',
          icon: Icons.workspace_premium,
          gradientColors: [
            AppTheme.secondaryColor,
            AppTheme.primaryColor,
          ],
          buttonText: 'Upgrade',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Premium coming soon!')),
            );
          },
        ),

        const SizedBox(height: 16),

        // Boost card
        _buildFeatureCard(
          icon: Icons.bolt,
          iconColor: AppTheme.tealAccent,
          badgeCount: 0,
          title: 'Boost',
          subtitle: 'Get seen by 11x more people',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Boosts coming soon!')),
            );
          },
        ),

        const SizedBox(height: 12),

        // Roses card
        _buildFeatureCard(
          icon: Icons.local_florist,
          iconColor: AppTheme.primaryLight,
          badgeCount: 1,
          title: 'Roses',
          subtitle: '2x as likely to lead to a date',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Roses coming soon!')),
            );
          },
        ),

        const SizedBox(height: 12),

        // Profile completeness card
        _buildFeatureCard(
          icon: Icons.stars,
          iconColor: AppTheme.warningColor,
          title: 'Profile Strength',
          subtitle: 'Complete profiles get 3x more likes',
          trailing: Text(
            '$_profileCompletion%',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          onTap: () => Navigator.pushNamed(context, '/profile'),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  // Tab 2: Safety (Verification, Block List, Resources)
  // ════════════════════════════════════════════════════════
  Widget _buildSafetyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Selfie Verification
        _buildSafetyCard(
          icon: Icons.verified_user,
          iconBgColor: AppTheme.secondaryColor.withValues(alpha: 0.15),
          iconColor: AppTheme.secondaryColor,
          isChecked: _isVerified,
          title: 'Selfie verification',
          subtitle: _isVerified ? "You're verified." : 'Verify your identity',
          onTap: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => const _VerificationSelfieRoute(),
              ),
            );
            if (result == true) {
              _loadProfileData(); // Refresh verification status
            }
          },
        ),

        const SizedBox(height: 12),

        // Comment Filter (placeholder — mirrors Hinge)
        _buildSafetyCard(
          icon: Icons.chat_bubble_outline,
          iconBgColor: AppTheme.secondaryColor.withValues(alpha: 0.15),
          iconColor: AppTheme.secondaryColor,
          isChecked: true,
          title: 'Comment Filter',
          subtitle: 'Hiding likes containing disrespectful\nlanguage.',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Comment filter settings coming soon')),
            );
          },
        ),

        const SizedBox(height: 12),

        // Block List
        _buildSafetyCard(
          icon: Icons.block,
          iconBgColor: AppTheme.secondaryColor.withValues(alpha: 0.15),
          iconColor: AppTheme.secondaryColor,
          isChecked: true,
          title: 'Block List',
          subtitle: 'Blocking $_blockedCount contact${_blockedCount == 1 ? '' : 's'}.',
          onTap: () {
            _showBlockListDialog();
          },
        ),

        const SizedBox(height: 32),

        // Explore safety resources header
        Text(
          'Explore safety resources',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),

        const SizedBox(height: 16),

        // Crisis Hotlines + Help Centre row
        Row(
          children: [
            Expanded(
              child: _buildResourceButton(
                icon: Icons.phone_in_talk,
                label: 'Crisis Hotlines',
                onTap: () => _launchUrl('https://www.iasp.info/resources/Crisis_Centres/'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildResourceButton(
                icon: Icons.help_outline,
                label: 'Help Centre',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help centre coming soon')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  // Tab 3: My DejTing (prompts, tips, settings, help)
  // ════════════════════════════════════════════════════════
  Widget _buildMyDejTingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Break new ice / Update prompts
        Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.question_answer_outlined,
                  size: 28,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Break new ice',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tired of the same convos? Answer a new\nPrompt for fresh conversations.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/profile'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.textPrimary),
                  foregroundColor: AppTheme.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                child: const Text('Update prompts'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Help Centre card
        _buildFeatureCard(
          icon: Icons.help_outline,
          iconColor: AppTheme.textSecondary,
          title: 'Help Centre',
          subtitle: 'Safety, Security and more',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Help centre coming soon')),
            );
          },
        ),

        const SizedBox(height: 12),

        // What Works card
        _buildFeatureCard(
          icon: Icons.lightbulb_outline,
          iconColor: AppTheme.textSecondary,
          title: 'What Works',
          subtitle: 'Check out our expert dating tips',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dating tips coming soon!')),
            );
          },
        ),

        const SizedBox(height: 12),

        // Settings card
        _buildFeatureCard(
          icon: Icons.settings,
          iconColor: AppTheme.textSecondary,
          title: 'Settings',
          subtitle: 'Discovery, notifications, privacy',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const _SettingsRoute(),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Logout button
        Center(
          child: TextButton(
            onPressed: _showLogoutDialog,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  // Shared UI Components
  // ════════════════════════════════════════════════════════

  Widget _buildPromoCard({
    required String title,
    required String subtitle,
    required IconData icon,
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
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
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
            // Icon with optional badge
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
                if (badgeCount != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.textTertiary,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyCard({
    required IconData icon,
    required Color iconBgColor,
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
            // Icon with checkmark overlay
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
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
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
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
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textTertiary,
            ),
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
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // Dialogs
  // ════════════════════════════════════════════════════════

  void _showBlockListDialog() async {
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
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Block List',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
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
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
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
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Logout'),
          ),
        ],
      ),
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
// Internal route wrappers (avoid circular imports)
// ════════════════════════════════════════════════════════

class _VerificationSelfieRoute extends StatelessWidget {
  const _VerificationSelfieRoute();

  @override
  Widget build(BuildContext context) {
    return const VerificationSelfieScreen();
  }
}


/// Minimal inline verification launcher — delegates to the real screen


class _SettingsRoute extends StatelessWidget {
  const _SettingsRoute();

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
  }
}

