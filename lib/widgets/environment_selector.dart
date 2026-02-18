import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../config/environment.dart';

class EnvironmentSelector extends StatefulWidget {
  const EnvironmentSelector({super.key});

  @override
  State<EnvironmentSelector> createState() => _EnvironmentSelectorState();
}

class _EnvironmentSelectorState extends State<EnvironmentSelector> {
  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Environment: ${EnvironmentConfig.settings.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Gateway: ${EnvironmentConfig.settings.gatewayUrl}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Keycloak: ${EnvironmentConfig.settings.keycloakUrl}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                _EnvironmentButton(
                  label: 'Development',
                  isSelected: EnvironmentConfig.isDevelopment,
                  onPressed: () {
                    setState(() {
                      EnvSwitcher.useDevelopment();
                    });
                    _showSnackBar('Switched to Development Environment');
                  },
                ),
                if (kDebugMode) // Only show production in debug for testing
                  _EnvironmentButton(
                    label: 'Production',
                    isSelected: EnvironmentConfig.isProduction,
                    onPressed: () {
                      setState(() {
                        EnvSwitcher.useProduction();
                      });
                      _showSnackBar('Switched to Production Environment');
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _EnvironmentButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _EnvironmentButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.orange : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }
}

// Quick environment info widget for debugging
class EnvironmentInfo extends StatelessWidget {
  const EnvironmentInfo({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: EnvironmentConfig.isDevelopment
            ? Colors.blue.withValues(alpha: 0.8)
            : Colors.red.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        EnvironmentConfig.settings.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
