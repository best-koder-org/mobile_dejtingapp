import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dejtingapp/config/environment.dart';

/// Monitors backend connectivity and shows a banner when services are unreachable.
class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _isOnline = true;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _checkTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkConnectivity();
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    try {
      final gatewayUrl = EnvironmentConfig.settings.gatewayUrl;
      final response = await http.get(
        Uri.parse('$gatewayUrl/health'),
      ).timeout(const Duration(seconds: 5));
      final online = response.statusCode >= 200 && response.statusCode < 500;
      if (mounted && online != _isOnline) {
        setState(() => _isOnline = online);
      }
    } catch (_) {
      if (mounted && _isOnline) {
        setState(() => _isOnline = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isOnline ? 0 : 36,
          color: Colors.orange.shade800,
          child: _isOnline
              ? const SizedBox.shrink()
              : const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Ingen anslutning — försöker igen...',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
