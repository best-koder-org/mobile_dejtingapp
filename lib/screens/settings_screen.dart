import 'package:dejtingapp/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:dejtingapp/services/api_service.dart';
import 'package:dejtingapp/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _showMeOnTinder = true;
  bool _showAgeInProfile = true;
  bool _showDistanceInProfile = true;
  double _maxDistance = 50.0;
  RangeValues _ageRange = const RangeValues(18, 35);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).settingsTitle),
        // Uses theme default AppBar
        // Uses theme default foreground
      ),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader(AppLocalizations.of(context).sectionAccount),
          ListTile(
            leading: const Icon(Icons.person, color: AppTheme.primaryColor),
            title: Text(AppLocalizations.of(context).editProfile),
            subtitle: Text(AppLocalizations.of(context).editProfileSubtitle),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.verified_user, color: AppTheme.primaryColor),
            title: Text(AppLocalizations.of(context).verifyAccount),
            subtitle: Text(AppLocalizations.of(context).verificationSubtitle),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Verification flow
            },
          ),
          ListTile(
            leading: const Icon(Icons.security, color: AppTheme.primaryColor),
            title: Text(AppLocalizations.of(context).privacySecurity),
            subtitle: Text(AppLocalizations.of(context).privacySecuritySubtitle),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Privacy settings
            },
          ),

          const Divider(height: 32),

          // Discovery Settings
          _buildSectionHeader(AppLocalizations.of(context).sectionDiscovery),
          ListTile(
            leading: const Icon(Icons.location_on, color: AppTheme.primaryColor),
            title: Text(AppLocalizations.of(context).locationLabel),
            subtitle: Text(AppLocalizations.of(context).locationSubtitle),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Location settings
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maximum Distance: ${_maxDistance.round()} km',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Slider(
                  value: _maxDistance,
                  min: 1,
                  max: 100,
                  divisions: 99,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _maxDistance = value;
                    });
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Age Range: ${_ageRange.start.round()} - ${_ageRange.end.round()}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                RangeSlider(
                  values: _ageRange,
                  min: 18,
                  max: 80,
                  divisions: 62,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (values) {
                    setState(() {
                      _ageRange = values;
                    });
                  },
                ),
              ],
            ),
          ),

          SwitchListTile(
            secondary: const Icon(Icons.visibility, color: AppTheme.primaryColor),
            title: Text(AppLocalizations.of(context).showMeOnDejTing),
            subtitle: Text(AppLocalizations.of(context).pauseAccountSubtitle),
            value: _showMeOnTinder,
            activeColor: AppTheme.primaryColor,
            onChanged: (value) {
              setState(() {
                _showMeOnTinder = value;
              });
            },
          ),

          const Divider(height: 32),

          // Notifications
          _buildSectionHeader(AppLocalizations.of(context).sectionNotifications),
          SwitchListTile(
            secondary: const Icon(Icons.notifications, color: AppTheme.primaryColor),
            title: Text(AppLocalizations.of(context).pushNotifications),
            subtitle: Text(AppLocalizations.of(context).notificationsSubtitle),
            value: _pushNotifications,
            activeColor: AppTheme.primaryColor,
            onChanged: (value) {
              setState(() {
                _pushNotifications = value;
              });
            },
          ),

          const Divider(height: 32),

          // Profile Display
          _buildSectionHeader(AppLocalizations.of(context).sectionProfileDisplay),
          SwitchListTile(
            secondary: const Icon(Icons.cake, color: AppTheme.primaryColor),
            title: Text(AppLocalizations.of(context).showAge),
            subtitle: Text(AppLocalizations.of(context).showAgeSubtitle),
            value: _showAgeInProfile,
            activeColor: AppTheme.primaryColor,
            onChanged: (value) {
              setState(() {
                _showAgeInProfile = value;
              });
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.location_on, color: AppTheme.primaryColor),
            title: Text(AppLocalizations.of(context).showDistance),
            subtitle: Text(AppLocalizations.of(context).showDistanceSubtitle),
            value: _showDistanceInProfile,
            activeColor: AppTheme.primaryColor,
            onChanged: (value) {
              setState(() {
                _showDistanceInProfile = value;
              });
            },
          ),

          const Divider(height: 32),

          // Support & About
          _buildSectionHeader(AppLocalizations.of(context).sectionSupportAbout),
          ListTile(
            leading: const Icon(Icons.help, color: AppTheme.primaryColor),
            title: Text(AppLocalizations.of(context).helpSupport),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Help screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.info, color: AppTheme.primaryColor),
            title: Text(AppLocalizations.of(context).aboutLabel),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showAboutDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.star, color: AppTheme.primaryColor),
            title: Text(AppLocalizations.of(context).rateUs),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Rate app
            },
          ),

          const SizedBox(height: 32),

          // Logout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: _showLogoutDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                // Uses theme default foreground
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(AppLocalizations.of(context).logoutButton),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).aboutApp),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Version: 1.0.0'),
                SizedBox(height: 8),
                Text('Find your perfect match with our AI-powered dating app.'),
                SizedBox(height: 16),
                Text('Made with ❤️ by the DatingApp Team'),
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
      builder:
          (context) => AlertDialog(
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
                    '/login',
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
