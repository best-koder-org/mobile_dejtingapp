import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../config/environment.dart';

/// Connection scenario description for a dev server option.
class _ServerOption {
  final String label;
  final String scenario;
  final IconData icon;
  final String url;

  const _ServerOption({
    required this.label,
    required this.scenario,
    required this.icon,
    required this.url,
  });
}

/// Scenario-based environment + server selector.
///
/// Labels describe real connection setups (USB/hotspot, same WiFi, etc.)
/// so it's clear which option matches your current hardware setup.
/// Shown as a collapsed bar; expands inline on the welcome screen dev panel.
class EnvironmentSelector extends StatefulWidget {
  const EnvironmentSelector({super.key});

  @override
  State<EnvironmentSelector> createState() => _EnvironmentSelectorState();
}

class _EnvironmentSelectorState extends State<EnvironmentSelector> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(190),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(40), width: 1),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        onExpansionChanged: (v) => setState(() => _expanded = v),
        tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        visualDensity: VisualDensity.compact,
        iconColor: Colors.orangeAccent,
        collapsedIconColor: Colors.orangeAccent,
        title: Row(
          children: [
            Icon(Icons.settings, size: 15, color: Colors.orangeAccent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _expanded ? '⚙️ Connection Settings' : '⚙️ ${_currentLabel()}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        children: [
          // ── Scrollable content (max 280px, scrolls if taller) ──
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Current gateway ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(100),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link, size: 12, color: Colors.green[300]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Gateway: ${EnvironmentConfig.settings.gatewayUrl}',
                          style: TextStyle(fontSize: 10, color: Colors.green[200]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // ── Environment chips ──
                Row(
                  children: [
                    const SizedBox(width: 4),
                    Text('Env:', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    const SizedBox(width: 6),
                    _EnvChip(
                      label: 'Dev',
                      isSelected: EnvironmentConfig.isDevelopment,
                      onTap: () { EnvSwitcher.useDevelopment(); setState(() {}); },
                    ),
                    const SizedBox(width: 4),
                    _EnvChip(
                      label: 'Staging',
                      isSelected: EnvironmentConfig.isStaging,
                      onTap: () { EnvSwitcher.useStaging(); setState(() {}); },
                    ),
                    const SizedBox(width: 4),
                    _EnvChip(
                      label: 'Prod',
                      isSelected: EnvironmentConfig.isProduction,
                      onTap: () { EnvSwitcher.useProduction(); setState(() {}); },
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // ── Divider ──
                Divider(color: Colors.white.withAlpha(30), height: 1),
                const SizedBox(height: 6),

                // ── Scenario radio options (main two backends) ──
                Text(
                  'Which backend?',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ..._mainServers.map((server) {
                  final opt = _optionFor(server);
                  return _ScenarioRadio(
                    icon: opt.icon,
                    label: opt.label,
                    scenario: opt.scenario,
                    url: opt.url,
                    value: server,
                    groupValue: EnvironmentConfig.devServer,
                    enabled: EnvironmentConfig.isDevelopment,
                    onChanged: (val) async {
                      await EnvSwitcher.switchDevServer(val);
                      setState(() {});
                    },
                    isSelected: EnvironmentConfig.devServer == server,
                  );
                }),

                // ── Advanced options (collapsed) ──
                if (EnvironmentConfig.isDevelopment)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(left: 4),
                    visualDensity: VisualDensity.compact,
                    iconColor: Colors.grey[500],
                    collapsedIconColor: Colors.grey[500],
                    title: Text(
                      'Advanced…',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    children: [
                      ..._advancedServers.map((server) {
                        final opt = _optionFor(server);
                        return _ScenarioRadio(
                          icon: opt.icon,
                          label: opt.label,
                          scenario: opt.scenario,
                          url: opt.url,
                          value: server,
                          groupValue: EnvironmentConfig.devServer,
                          enabled: EnvironmentConfig.isDevelopment,
                          onChanged: (val) async {
                            await EnvSwitcher.switchDevServer(val);
                            setState(() {});
                          },
                          isSelected: EnvironmentConfig.devServer == server,
                        );
                      }),
                      // ── Custom host input (advanced) ──
                      if (EnvironmentConfig.devServer == DevServer.custom)
                        const _CustomHostInput(),
                    ],
                  ),

                // ── Custom host input when Custom IP selected ──
                if (EnvironmentConfig.isDevelopment &&
                    EnvironmentConfig.devServer == DevServer.custom)
                  const _CustomHostInput(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The two main backends most users need. Everything else goes under Advanced.
  static const List<DevServer> _mainServers = [
    DevServer.local, // Laptop (dev machine) via USB
    DevServer.funnel, // Always-on server, works from anywhere
  ];

  /// Secondary options — hidden under "Advanced" (Custom IP, Same WiFi LAN).
  static const List<DevServer> _advancedServers = [
    DevServer.custom,
    DevServer.server,
  ];

  _ServerOption _optionFor(DevServer s) {
    switch (s) {
      case DevServer.local:
        return _ServerOption(
          label: 'Laptop (dev)',
          scenario: 'Your dev laptop via USB cable (adb reverse)',
          icon: Icons.laptop,
          url: EnvironmentConfig.isEmulator
              ? '10.0.2.2:8080 (emulator)'
              : 'localhost:8080 (adb reverse)',
        );
      case DevServer.server:
        return _ServerOption(
          label: 'Same WiFi (LAN)',
          scenario: 'Phone & laptop on the same WiFi network',
          icon: Icons.wifi,
          url: EnvironmentConfig.settings.gatewayUrl,
        );
      case DevServer.funnel:
        return _ServerOption(
          label: 'Server (always-on)',
          scenario: 'The little computer — works from any network',
          icon: Icons.dns,
          url: 'a.tail45c6a7.ts.net',
        );
      case DevServer.custom:
        return _ServerOption(
          label: 'Custom IP',
          scenario: 'Enter server address manually',
          icon: Icons.edit,
          url: EnvironmentConfig.customHost.isNotEmpty
              ? '${EnvironmentConfig.customHost}:8080'
              : 'Enter host or IP',
        );
    }
  }

  String _currentLabel() {
    final env = EnvironmentConfig.isDevelopment
        ? 'Dev'
        : EnvironmentConfig.isStaging
            ? 'Staging'
            : 'Prod';
    final opt = _optionFor(EnvironmentConfig.devServer);
    return '$env · ${opt.label}';
  }
}

/// A compact chip-style button for environment selection.
class _EnvChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _EnvChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange.withAlpha(200)
              : Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orangeAccent : Colors.white.withAlpha(40),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Text input for the Custom IP host, shown when Custom IP is selected.
class _CustomHostInput extends StatefulWidget {
  const _CustomHostInput();

  @override
  State<_CustomHostInput> createState() => _CustomHostInputState();
}

class _CustomHostInputState extends State<_CustomHostInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: EnvironmentConfig.customHost);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SizedBox(
        height: 34,
        child: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'e.g. 192.168.1.100',
            hintStyle: TextStyle(fontSize: 11, color: Colors.grey[500]),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: Colors.black.withAlpha(80),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.orangeAccent.withAlpha(100)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.white.withAlpha(30)),
            ),
          ),
          style: const TextStyle(fontSize: 12, color: Colors.white),
          onSubmitted: (val) async {
            if (val.trim().isNotEmpty) {
              await EnvSwitcher.switchDevServer(
                  DevServer.custom, customHost: val.trim());
              if (mounted) setState(() {});
            }
          },
        ),
      ),
    );
  }
}

/// Radio row with icon, scenario description, and URL.
class _ScenarioRadio extends StatelessWidget {
  final IconData icon;
  final String label;
  final String scenario;
  final String url;
  final DevServer value;
  final DevServer groupValue;
  final bool enabled;
  final ValueChanged<DevServer> onChanged;
  final bool isSelected;

  const _ScenarioRadio({
    required this.icon,
    required this.label,
    required this.scenario,
    required this.url,
    required this.value,
    required this.groupValue,
    required this.enabled,
    required this.onChanged,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onChanged(value) : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange.withAlpha(50)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(color: Colors.orangeAccent.withAlpha(120), width: 1)
              : null,
        ),
        child: Row(
          children: [
            // Radio button
            SizedBox(
              width: 22,
              child: Radio<DevServer>(
                value: value,
                groupValue: groupValue,
                onChanged: enabled ? (v) => onChanged(v!) : null,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: Colors.orangeAccent,
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.orangeAccent;
                  }
                  return Colors.white54;
                }),
              ),
            ),
            const SizedBox(width: 4),
            // Icon
            Icon(icon, size: 16, color: isSelected ? Colors.orangeAccent : Colors.white70),
            const SizedBox(width: 6),
            // Label + scenario
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.orangeAccent : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  Text(
                    scenario,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            // URL
            Flexible(
              child: Text(
                url,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected ? Colors.green[300] : Colors.grey[600],
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compact environment info badge (for app bar) ───────────────────────────

class EnvironmentInfo extends StatefulWidget {
  const EnvironmentInfo({super.key});

  @override
  State<EnvironmentInfo> createState() => _EnvironmentInfoState();
}

class _EnvironmentInfoState extends State<EnvironmentInfo>
    with SingleTickerProviderStateMixin {
  bool _serverOnline = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    try {
      final uri = Uri.parse('${EnvironmentConfig.settings.gatewayUrl}/health');
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (mounted) {
        setState(() {
          _serverOnline = response.statusCode == 200;
          _checked = true;
        });
      }
      client.close();
    } catch (_) {
      if (mounted) {
        setState(() {
          _serverOnline = false;
          _checked = true;
        });
      }
    }
    Future.delayed(const Duration(seconds: 15), _checkServer);
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final Color bgColor;
    if (EnvironmentConfig.isDevelopment) {
      bgColor = Colors.blue.withValues(alpha: 0.8);
    } else if (EnvironmentConfig.isStaging) {
      bgColor = Colors.orange.withValues(alpha: 0.8);
    } else {
      bgColor = Colors.red.withValues(alpha: 0.8);
    }

    final serverLabel = EnvironmentConfig.isDevelopment
        ? _serverShortLabel()
        : EnvironmentConfig.settings.name.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _checked
                  ? (_serverOnline ? Colors.greenAccent : Colors.redAccent)
                  : Colors.yellowAccent,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            serverLabel,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Text(
            _hostShort(),
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
        ],
      ),
    );
  }

  String _serverShortLabel() {
    switch (EnvironmentConfig.devServer) {
      case DevServer.server: return 'SERVER';
      case DevServer.funnel: return 'FUNNEL';
      case DevServer.custom: return 'CUSTOM';
      case DevServer.local: return 'LOCAL';
    }
  }

  String _hostShort() {
    final url = EnvironmentConfig.settings.gatewayUrl
        .replaceAll('http://', '').replaceAll('https://', '');
    final parts = url.split(':');
    return parts.isNotEmpty ? parts[0] : url;
  }
}
