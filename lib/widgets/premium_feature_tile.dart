import 'package:flutter/material.dart';

/// A settings tile for premium features.
///
/// **Free users**: tile is dimmed (opacity 0.5), shows a lock icon + gold "PREMIUM" badge,
/// and tapping opens an upgrade prompt instead of toggling.
///
/// **Paying users**: full opacity, active toggle, normal icon.
class PremiumFeatureTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isPremium;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onUpgrade;

  const PremiumFeatureTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.isPremium,
    required this.value,
    this.onChanged,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !isPremium;

    return Opacity(
      opacity: locked ? 0.5 : 1.0,
      child: SwitchListTile(
        secondary: locked
            ? Icon(Icons.lock, color: Colors.amber.shade700)
            : Icon(icon, color: Colors.amber.shade700),
        title: Row(
          children: [
            Flexible(
              child: Text(title, style: const TextStyle(fontSize: 14)),
            ),
            if (locked) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PREMIUM',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: locked
            ? Text(
                'Lås upp med Premium',
                style: TextStyle(color: Colors.amber.shade700, fontSize: 12),
              )
            : subtitle != null
                ? Text(subtitle!, style: const TextStyle(fontSize: 12))
                : null,
        value: value,
        onChanged: locked ? (_) => onUpgrade?.call() : onChanged,
        activeColor: Colors.amber.shade700,
      ),
    );
  }
}

/// A banner shown at the top of the premium section for free users,
/// encouraging them to upgrade.
class PremiumUpgradeBanner extends StatelessWidget {
  final VoidCallback onUpgrade;

  const PremiumUpgradeBanner({super.key, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade700, Colors.amber.shade600],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.diamond, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Uppgradera till Premium för läskvitton och fler funktioner',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: onUpgrade,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Visa', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
