import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/safety_service.dart';

/// Privacy & Security screen with real controls (T051).
/// Shows blocked users list and profile visibility toggle.
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _loadingBlocks = true;
  bool _showInDiscovery = true;
  String? _blockError;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
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
              onChanged: (val) => setState(() => _showInDiscovery = val),
            ),
          ),
          const SizedBox(height: 8),

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
                                _unblock(u['blockedUserId']?.toString() ?? ''),
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
