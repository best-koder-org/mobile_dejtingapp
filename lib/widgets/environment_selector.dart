import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../config/environment.dart';

/// Compact environment + dev server selector for debug overlays.
///
/// Shows as a collapsed expansion tile by default (single line with gear icon
/// and current server). Expands inline to reveal environment buttons and
/// server radio options. Designed to fit in tight spaces like the welcome
/// screen dev panel without causing overflow.
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
      constraints: const BoxConstraints(maxHeight: 340),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.black12),
        child: ExpansionTile(
          initiallyExpanded: false,
          onExpansionChanged: (v) => setState(() => _expanded = v),
          tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          visualDensity: VisualDensity.compact,
          iconColor: Colors.black54,
          collapsedIconColor: Colors.black38,
          title: Row(
            children: [
              Icon(Icons.settings, size: 16, color: Colors.orange[300]),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _expanded ? 'Server Settings' : 'Server: ${_currentLabel()}',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          children: [
            // ── Current info ──
            Text(
              'Gateway: ${EnvironmentConfig.settings.gatewayUrl}',
              style: TextStyle(fontSize: 10, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            // ── Environment buttons ──
            Row(
              children: [
                const SizedBox(width: 8),
                Text('Env:', style: TextStyle(fontSize: 11, color: Colors.black54)),
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
            // ── Dev server picker ──
            Text('Dev Server:', style: TextStyle(fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 2),
            ...DevServer.values.map((server) => _CompactRadio(
              label: _serverLabel(server),
              subtitle: _serverUrl(server),
              value: server,
              groupValue: EnvironmentConfig.devServer,
              enabled: EnvironmentConfig.isDevelopment,
              onChanged: (val) async {
                await EnvSwitcher.switchDevServer(val);
                setState(() {});
              },
            )),
            // ── Custom host input ──
            if (EnvironmentConfig.isDevelopment && EnvironmentConfig.devServer == DevServer.custom)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'host:port',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    controller: TextEditingController(text: EnvironmentConfig.customHost),
                    onSubmitted: (val) async {
                      if (val.trim().isNotEmpty) {
                        await EnvSwitcher.switchDevServer(DevServer.custom, customHost: val.trim());
                        setState(() {});
                      }
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _currentLabel() {
    final env = EnvironmentConfig.isDevelopment ? 'Dev' : EnvironmentConfig.isStaging ? 'Staging' : 'Prod';
    return '$env · ${_serverLabel(EnvironmentConfig.devServer)}';
  }

  String _serverLabel(DevServer s) {
    switch (s) {
      case DevServer.server: return 'LAN';
      case DevServer.funnel: return 'Funnel';
      case DevServer.custom: return 'Custom';
      case DevServer.local: return 'Local';
    }
  }

  String _serverUrl(DevServer s) {
    switch (s) {
      case DevServer.server: return '192.168.1.103:8080';
      case DevServer.funnel: return 'a.tail45c6a7.ts.net';
      case DevServer.custom:
        return EnvironmentConfig.customHost.isNotEmpty
            ? '${EnvironmentConfig.customHost}:8080'
            : 'Enter host:port';
      case DevServer.local:
        return '10.0.2.2:8080 (emu) / localhost (web)';
    }
  }
}

/// A compact chip-style button for environment selection.
class _EnvChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _EnvChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.withAlpha(179) : Colors.black.withAlpha(30),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.orange : Colors.black26, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black87 : Colors.black54,
          ),
        ),
      ),
    );
  }
}

/// A compact radio button row for the dev server picker.
class _CompactRadio extends StatelessWidget {
  final String label;
  final String subtitle;
  final DevServer value;
  final DevServer groupValue;
  final bool enabled;
  final ValueChanged<DevServer> onChanged;

  const _CompactRadio({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: enabled ? () => onChanged(value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 20, height: 20,
              child: Radio<DevServer>(
                value: value,
                groupValue: groupValue,
                onChanged: enabled ? (v) => onChanged(v!) : null,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.black87 : Colors.black54,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.black45),
              overflow: TextOverflow.ellipsis,
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
