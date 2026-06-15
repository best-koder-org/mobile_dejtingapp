import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/safety_service.dart';
import '../services/api_service.dart';

/// Privacy & Security screen with real controls.
/// Show in discovery, incognito mode, message filter, and blocked users list.
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _loadingBlocks = true;
  bool _loadingSettings = true;
  String? _blockError;

  // Backend-synced toggles
  bool _showInDiscovery = true;
  bool _incognitoMode = false;
  String _messageFilter = 'Off';

  final List<String> _messageFilterOptions = ['Off', 'Disrespectful', 'AllOffensive'];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadBlockedUsers(), _loadPrivacySettings()]);
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _loadingBlocks = true;
      _blockError = null;
    });
    try {
      final users = await SafetyService.getBlockedUsers();
      if (!mounted) return;
      setState(() {
        _blockedUsers = users;
        _loadingBlocks = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _blockError = 'Could not load blocked users';
        _loadingBlocks = false;
      });
    }
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final prefs = await UserService.getPreferences();
      if (prefs != null && mounted) {
        setState(() {
          _showInDiscovery = (prefs['showMeInDiscovery'] as bool?) ?? true;
        });
      }

      final profile = await UserService.getUserProfile(
        AppState().userId ?? '',
      );
      if (profile != null && mounted) {
        setState(() {
          _incognitoMode = (profile['isPrivate'] as bool?) ?? false;
          _messageFilter = (profile['messageFilterLevel'] as String?) ?? 'Off';
          _loadingSettings = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to load privacy settings: $e');
    } finally {
      if (mounted) setState(() => _loadingSettings = false);
    }
  }

  Future<void> _saveShowInDiscovery(bool value) async {
    setState(() => _showInDiscovery = value);
    await UserService.updatePreferences({'showMeInDiscovery': value});
  }

  Future<void> _saveIncognitoMode(bool value) async {
    setState(() => _incognitoMode = value);
    await UserService.updatePrivacySettings({
      'showAge': true,
      'showDistance': true,
      'showOnlineStatus': true,
      'isPrivate': value,
    });
  }

  Future<void> _saveMessageFilter(String value) async {
    setState(() => _messageFilter = value);
    await UserService.updatePrivacySettings({
      'showAge': true,
      'showDistance': true,
      'showOnlineStatus': true,
      'messageFilterLevel': value,
    });
  }

  Future<void> _unblock(String blockedUserId) async {
    try {
      await SafetyService.unblockUser(blockedUserId);
      if (!mounted) return;
      setState(() {
        _blockedUsers.removeWhere(
            (u) => u['blockedUserId'] == blockedUserId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User unblocked')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unblock: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loadingSettings) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.privacySettingsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacySettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile visibility ──
          Card(
            child: SwitchListTile(
              title: const Text('Show me in discovery'),
              subtitle: const Text(
                  'Control whether your profile appears in the swipe deck'),
              value: _showInDiscovery,
              onChanged: _saveShowInDiscovery,
            ),
          ),
          const SizedBox(height: 8),

          // ── Incognito mode ──
          Card(
            child: SwitchListTile(
              title: const Text('Incognito mode'),
              subtitle: const Text(
                  'Only people you\'ve liked can see your profile. '
                  'You won\'t appear in discovery for anyone else.'),
              value: _incognitoMode,
              onChanged: _saveIncognitoMode,
            ),
          ),
          const SizedBox(height: 8),

          // ── Message filter ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Message filter',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  const Text(
                      'Filter potentially offensive messages from matches',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _messageFilter,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    items: _messageFilterOptions.map((level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Text(level),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) _saveMessageFilter(value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Blocked users ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Blocked users',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_loadingBlocks)
                    const Center(child: CircularProgressIndicator())
                  else if (_blockError != null)
                    Column(
                      children: [
                        Text(_blockError!,
                            style: const TextStyle(color: Colors.red)),
                        TextButton(
                            onPressed: _loadBlockedUsers,
                            child: const Text('Retry')),
                      ],
                    )
                  else if (_blockedUsers.isEmpty)
                    const Text('No blocked users',
                        style: TextStyle(color: Colors.grey))
                  else
                    ..._blockedUsers.map((u) => ListTile(
                          leading: const Icon(Icons.person_off),
                          title: Text(u['blockedUserId']?.toString() ??
                              'Unknown'),
                          trailing: IconButton(
                            icon: const Icon(Icons.undo, color: Colors.grey),
                            tooltip: 'Unblock',
                            onPressed: () =>
                                _unblock(u['blockedUserId'].toString()),
                          ),
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
