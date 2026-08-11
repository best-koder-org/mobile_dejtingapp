import 'package:dejtingapp/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:dejtingapp/screens/help_screen.dart';
import 'package:dejtingapp/screens/location_settings_screen.dart';
import 'package:dejtingapp/screens/premium_comparison_screen.dart';
import 'package:dejtingapp/screens/privacy_settings_screen.dart';
import 'package:dejtingapp/screens/verification_selfie_screen.dart';
import 'package:dejtingapp/services/api_service.dart';
import 'package:dejtingapp/services/billing_service.dart';
import 'package:dejtingapp/widgets/premium_feature_tile.dart';
import 'package:dejtingapp/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dejtingapp/config/environment.dart';
import 'package:dejtingapp/main.dart' show setAppLocale, appLocale;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- Backend-synced state ---
  bool _isLoading = true;
  String? _loadError;

  // Discovery preferences (from MatchPreferences)
  double _maxDistance = 50.0;
  RangeValues _ageRange = const RangeValues(18, 35);
  bool _showMeOnDejting = true;

  // Privacy display toggles (from UserProfile)
  bool _showAgeInProfile = true;
  bool _showDistanceInProfile = true;

  // Premium features
  bool _isPremium = false;
  bool _privacyReadReceipts = false;

  // Notifications
  bool _pushNotifications = true;

  // Profile strength & account pause
  int _profileStrength = 0;
  String? _completenessSuggestion;
  bool _isPaused = false;
  bool _isPausing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      // Load discovery preferences from backend
      final prefs = await UserService.getPreferences();
      if (prefs != null && mounted) {
        setState(() {
          _maxDistance = (prefs['maxDistanceKm'] as num?)?.toDouble() ?? 50.0;
          final minAge = (prefs['minAge'] as num?)?.toDouble() ?? 18.0;
          final maxAge = (prefs['maxAge'] as num?)?.toDouble() ?? 35.0;
          _ageRange = RangeValues(minAge, maxAge);
          _showMeOnDejting = (prefs['showMeInDiscovery'] as bool?) ?? true;
        });
      }

      // Load privacy settings from profile
      final profile = await UserService.getUserProfile(
        AppState().userId ?? '',
      );
      if (profile != null && mounted) {
        setState(() {
          _showAgeInProfile = (profile['showAge'] as bool?) ?? true;
          _showDistanceInProfile = (profile['showDistance'] as bool?) ?? true;
          _privacyReadReceipts = (profile['readReceiptsEnabled'] as bool?) ?? false;
        });
      }

      // Load premium status
      try {
        final status = await BillingService.getStatus();
        if (mounted) {
          setState(() => _isPremium = status.isPremium);
        }
      } catch (_) {}

      // Load notification preferences
      final notifPrefs = await UserService.getNotificationPreferences();
      if (notifPrefs != null && mounted) {
        final data = notifPrefs['data'] as Map<String, dynamic>? ?? notifPrefs;
        setState(() {
          _pushNotifications = (data['pushEnabled'] as bool?) ?? true;
        });
      }

      // Load profile strength
      final completeness = await UserService.getProfileCompleteness();
      if (completeness != null && mounted) {
        final data = completeness['data'] as Map<String, dynamic>? ?? completeness;
        setState(() {
          _profileStrength = (data['percentage'] as num?)?.toInt() ?? 0;
          if (data['missingFields'] is List && (data['missingFields'] as List).isNotEmpty) {
            final first = (data['missingFields'] as List).first;
            _completenessSuggestion = first['fieldName']?.toString();
          }
        });
      }

      // Load account status
      final status = await UserService.getAccountStatus();
      if (status != null && mounted) {
        final data = status['data'] as Map<String, dynamic>? ?? status;
        final statusVal = data['status']?.toString() ?? 'Active';
        setState(() => _isPaused = statusVal == 'Paused');
      }
    } catch (e) {
      debugPrint('❌ Failed to load settings: $e');
      if (mounted) {
        setState(() => _loadError = 'Failed to load settings');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    await UserService.updatePreferences({
      'maxDistanceKm': _maxDistance.round(),
      'minAge': _ageRange.start.round(),
      'maxAge': _ageRange.end.round(),
      'showMeInDiscovery': _showMeOnDejting,
    });
  }

  Future<void> _savePrivacy() async {
    await UserService.updatePrivacySettings({
      'showAge': _showAgeInProfile,
      'showDistance': _showDistanceInProfile,
      'readReceiptsEnabled': _privacyReadReceipts,
    });
  }

  Future<void> _saveNotificationPrefs() async {
    await UserService.updateNotificationPreferences({
      'pushEnabled': _pushNotifications,
      'matchNotifications': _pushNotifications,
      'messageNotifications': _pushNotifications,
      'sparkNotifications': _pushNotifications,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'screen:settings',
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).settingsTitle),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSettings,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // ── Profile Strength Card (top) ──
        _buildProfileStrengthCard(),
        const SizedBox(height: 12),

        // ── Discovery Card ──
        _buildSettingsCard(
          title: AppLocalizations.of(context).sectionDiscovery,
          children: [
            ListTile(
              leading: const Icon(Icons.location_on, color: AppTheme.primaryColor),
              title: Text(AppLocalizations.of(context).locationLabel),
              subtitle: Text(AppLocalizations.of(context).locationSubtitle),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocationSettingsScreen()),
              ),
            ),
            const Divider(height: 1),
            _buildSliderTile(
              'Maximum Distance: ${_maxDistance.round()} km',
              Slider(
                value: _maxDistance, min: 1, max: 100, divisions: 99,
                activeColor: AppTheme.primaryColor,
                onChanged: (v) => setState(() => _maxDistance = v),
                onChangeEnd: (_) => _savePreferences(),
              ),
            ),
            _buildSliderTile(
              'Age Range: ${_ageRange.start.round()} - ${_ageRange.end.round()}',
              RangeSlider(
                values: _ageRange, min: 18, max: 80, divisions: 62,
                activeColor: AppTheme.primaryColor,
                onChanged: (v) => setState(() => _ageRange = v),
                onChangeEnd: (_) => _savePreferences(),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.visibility, color: AppTheme.primaryColor, size: 20),
              title: const Text('Show me on DejTing', style: TextStyle(fontSize: 14)),
              value: _showMeOnDejting,
              activeColor: AppTheme.primaryColor,
              onChanged: (v) { setState(() => _showMeOnDejting = v); _savePreferences(); },
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Profile Display Card ──
        _buildSettingsCard(
          title: AppLocalizations.of(context).sectionProfileDisplay,
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.cake, color: AppTheme.primaryColor, size: 20),
              title: Text(AppLocalizations.of(context).showAge, style: const TextStyle(fontSize: 14)),
              subtitle: Text(AppLocalizations.of(context).showAgeSubtitle, style: const TextStyle(fontSize: 12)),
              value: _showAgeInProfile,
              activeColor: AppTheme.primaryColor,
              onChanged: (v) { setState(() => _showAgeInProfile = v); _savePrivacy(); },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 20),
              title: Text(AppLocalizations.of(context).showDistance, style: const TextStyle(fontSize: 14)),
              subtitle: Text(AppLocalizations.of(context).showDistanceSubtitle, style: const TextStyle(fontSize: 12)),
              value: _showDistanceInProfile,
              activeColor: AppTheme.primaryColor,
              onChanged: (v) { setState(() => _showDistanceInProfile = v); _savePrivacy(); },
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Premium Features Card ──
        if (!_isPremium)
          PremiumUpgradeBanner(onUpgrade: _showUpgradePrompt),
        _buildSettingsCard(
          title: 'Premium-funktioner',
          leadingIcon: Icons.diamond,
          leadingColor: Colors.amber.shade700,
          children: [
            PremiumFeatureTile(
              title: 'Läskvitton',
              subtitle: 'Se när dina meddelanden har lästs',
              icon: Icons.done_all,
              isPremium: _isPremium,
              value: _privacyReadReceipts,
              onChanged: (v) {
                setState(() => _privacyReadReceipts = v);
                _savePrivacy();
              },
              onUpgrade: _showUpgradePrompt,
            ),
            const Divider(height: 1),
            PremiumFeatureTile(
              title: 'Dold surfning',
              subtitle: 'Ingen ser att du besökt deras profil',
              icon: Icons.visibility_off,
              isPremium: _isPremium,
              value: false,
              onChanged: null,
              onUpgrade: _showUpgradePrompt,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Privacy & Safety Card ──
        _buildSettingsCard(
          title: 'Privacy & Safety',
          children: [
            ListTile(
              leading: const Icon(Icons.security, color: AppTheme.primaryColor, size: 20),
              title: const Text('Privacy & Security', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Incognito, message filter, blocked users', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Notifications Card ──
        _buildSettingsCard(
          title: AppLocalizations.of(context).sectionNotifications,
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.notifications, color: AppTheme.primaryColor, size: 20),
              title: Text(AppLocalizations.of(context).pushNotifications, style: const TextStyle(fontSize: 14)),
              subtitle: Text(AppLocalizations.of(context).notificationsSubtitle, style: const TextStyle(fontSize: 12)),
              value: _pushNotifications,
              activeColor: AppTheme.primaryColor,
              onChanged: (v) { setState(() => _pushNotifications = v); _saveNotificationPrefs(); },
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Account Card ──
        _buildSettingsCard(
          title: AppLocalizations.of(context).sectionAccount,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: AppTheme.primaryColor, size: 20),
              title: Text(AppLocalizations.of(context).editProfile, style: const TextStyle(fontSize: 14)),
              subtitle: const Text('Update your photos, bio, and preferences', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            _buildPauseTile(),
            ListTile(
              leading: const Icon(Icons.verified_user, color: AppTheme.primaryColor, size: 20),
              title: Text(AppLocalizations.of(context).verifyAccount, style: const TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VerificationSelfieScreen()),
              ),
            ),
            // ── Language toggle ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text('Language / Språk', style: TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<Locale>(
                    valueListenable: appLocale,
                    builder: (context, locale, _) {
                      return SegmentedButton<String>(
                        style: SegmentedButton.styleFrom(
                          backgroundColor: AppTheme.surfaceColor,
                          selectedBackgroundColor: AppTheme.primaryColor,
                          selectedForegroundColor: Colors.white,
                          foregroundColor: AppTheme.textSecondary,
                          side: const BorderSide(color: AppTheme.dividerColor),
                        ),
                        segments: const [
                          ButtonSegment(value: 'en', label: Text('🇬🇧 English')),
                          ButtonSegment(value: 'sv', label: Text('🇸🇪 Svenska')),
                        ],
                        selected: {locale.languageCode},
                        onSelectionChanged: (sel) => setAppLocale(Locale(sel.first)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Support Card ──
        _buildSettingsCard(
          title: AppLocalizations.of(context).sectionSupportAbout,
          children: [
            ListTile(
              leading: const Icon(Icons.help, color: AppTheme.primaryColor, size: 20),
              title: const Text('Help & FAQ', style: TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const HelpScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info, color: AppTheme.primaryColor, size: 20),
              title: Text(AppLocalizations.of(context).aboutLabel, style: const TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showAboutDialog,
            ),
            ListTile(
              leading: const Icon(Icons.star, color: AppTheme.primaryColor, size: 20),
              title: Text(AppLocalizations.of(context).rateUs, style: const TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _rateApp,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Developer Settings ──
        _buildSettingsCard(
          title: 'Developer Settings',
          leadingIcon: Icons.developer_mode,
          leadingColor: Colors.purple,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Backend Server',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  ...DevServer.values.map((server) {
                    final labels = {
                      DevServer.local: 'Laptop (dev)',
                      DevServer.server: 'Same WiFi (LAN)',
                      DevServer.funnel: 'Server (always-on)',
                      DevServer.custom: 'Custom IP',
                    };
                    return RadioListTile<DevServer>(
                      title: Text(labels[server] ?? server.name,
                          style: const TextStyle(fontSize: 13)),
                      subtitle: Text(_devServerUrl(server),
                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                      value: server,
                      groupValue: EnvironmentConfig.devServer,
                      activeColor: AppTheme.primaryColor,
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      onChanged: (val) async {
                        if (val == null) return;
                        if (val == DevServer.custom) {
                          final ctrl = TextEditingController(text: EnvironmentConfig.customHost);
                          final host = await showDialog<String>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Custom Server'),
                              content: TextField(
                                controller: ctrl,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 192.168.1.100',
                                  labelText: 'IP or hostname',
                                ),
                                autofocus: true,
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                          if (host != null && host.isNotEmpty) {
                            await EnvSwitcher.switchDevServer(val, customHost: host);
                          }
                        } else {
                          await EnvSwitcher.switchDevServer(val);
                        }
                        setState(() {});
                      },
                    );
                  }),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
              title: const Text('Gateway URL', style: TextStyle(fontSize: 13)),
              subtitle: Text(EnvironmentConfig.settings.gatewayUrl,
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Logout ──
        ElevatedButton(
          onPressed: _showLogoutDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
          child: Text(AppLocalizations.of(context).logoutButton),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }


  String _devServerUrl(DevServer server) {
    switch (server) {
      case DevServer.local:
        return 'http://localhost:8080 (USB/adb reverse)';
      case DevServer.server:
        return 'http://100.86.173.9:8080';
      case DevServer.funnel:
        return 'https://a.tail45c6a7.ts.net';
      case DevServer.custom:
        final h = EnvironmentConfig.customHost;
        return h.isNotEmpty ? 'http://$h:8080' : 'Enter host';
    }
  }

  void _showUpgradePrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.diamond, color: Colors.amber.shade700, size: 32),
        title: const Text('Bli Premium'),
        content: const Text(
          'Premium-medlemmar får tillgång till:\n\n'
          '• Läskvitton – se när dina meddelanden har lästs\n'
          '• Dold surfning – ingen ser att du besökt deras profil\n'
          '• Fler premium-funktioner kommer snart',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Senare'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const PremiumComparisonScreen(),
              ));
            },
            child: const Text('Se Premium-planer'),
          ),
        ],
      ),
    );
  }

  Future<void> _rateApp() async {
    final uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.dejting.app',
    );
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).couldNotOpenStore),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).couldNotOpenStore),
          ),
        );
      }
    }
  }

  Widget _buildSettingsCard({
    required String title,
    required List<Widget> children,
    IconData? leadingIcon,
    Color? leadingColor,
  }) {
    return Card(
      elevation: 0,
      color: AppTheme.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: AppTheme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, color: leadingColor ?? AppTheme.primaryColor, size: 18),
                  const SizedBox(width: 6),
                ],
                Text(title,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: leadingColor ?? AppTheme.primaryColor, letterSpacing: 0.5,
                    ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSliderTile(String label, Widget slider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          slider,
        ],
      ),
    );
  }

  Widget _buildProfileStrengthCard() {
    final color = _profileStrength < 40
        ? Colors.red
        : _profileStrength < 70
            ? Colors.orange
            : Colors.green;
    final message = _profileStrength < 40
        ? 'Complete your profile to get more matches'
        : _profileStrength < 70
            ? 'Keep going! Add more details to stand out'
            : 'Great profile! You\'re all set.';
    return Card(
      elevation: 0,
      color: AppTheme.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: AppTheme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 48, height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _profileStrength / 100.0,
                    color: color,
                    backgroundColor: AppTheme.dividerColor,
                    strokeWidth: 4,
                  ),
                  Text('$_profileStrength%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profile Strength',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(message,
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  if (_completenessSuggestion != null && _profileStrength < 100)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Tip: Add ${_completenessSuggestion}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor)),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              color: AppTheme.primaryColor,
              onPressed: () => Navigator.pushNamed(context, '/profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseTile() {
    return ListTile(
      leading: Icon(
        _isPaused ? Icons.play_arrow : Icons.pause,
        color: AppTheme.primaryColor, size: 20,
      ),
      title: Text(
        _isPaused ? 'Resume Account' : 'Pause Account',
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        _isPaused ? 'Your profile is hidden' : 'Temporarily hide your profile',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: _isPausing
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: _isPausing ? null : _isPaused ? _handleResume : _showPauseDialog,
    );
  }

  void _showPauseDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Pause Account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Your profile will be hidden from everyone.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            _pauseOption('24 hours', 'Hours24'),
            _pauseOption('72 hours', 'Hours72'),
            _pauseOption('1 week', 'OneWeek'),
            _pauseOption('Indefinitely', 'Indefinite'),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pauseOption(String label, String duration) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () async {
          Navigator.pop(context); // close bottom sheet
          setState(() => _isPausing = true);
          final ok = await UserService.pauseAccount(duration: duration);
          if (mounted) {
            setState(() {
              _isPausing = false;
              _isPaused = ok;
            });
            if (ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Account paused for $label')),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.surfaceElevated,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            side: BorderSide(color: AppTheme.dividerColor),
          ),
        ),
        child: Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
      ),
    );
  }

  Future<void> _handleResume() async {
    setState(() => _isPausing = true);
    final ok = await UserService.resumeAccount();
    if (mounted) {
      setState(() {
        _isPausing = false;
        _isPaused = !ok;
      });
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account resumed!')),
        );
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).aboutApp),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).versionNumber),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context).aboutAppDescription),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).madeByTeam),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).okButton),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).logoutButton),
        content: Text(AppLocalizations.of(context).logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancelButton),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AppState().logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/welcome',
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).logoutButton),
          ),
        ],
      ),
    );
  }
}
