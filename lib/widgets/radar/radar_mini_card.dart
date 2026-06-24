import 'package:flutter/material.dart';
import 'package:dejtingapp/services/radar_service.dart';
import 'package:dejtingapp/widgets/radar/radar_chart_widget.dart';
import 'package:dejtingapp/screens/radar_profile_screen.dart';
import 'package:dejtingapp/theme/app_theme.dart';

/// A compact radar profile card for insertion into match insight, profile hub, etc.
/// Shows a mini radar chart + confidence indicator. Tappable → opens full screen.
class RadarMiniCard extends StatelessWidget {
  final RadarProfileData? profile;
  final VoidCallback? onTap;

  const RadarMiniCard({super.key, this.profile, this.onTap});

  static const _accent = Color(0xFF6B4EFF);

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return _buildEmpty(context);
    }

    return GestureDetector(
      onTap: onTap ?? () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const RadarProfileScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accent.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            RadarChartWidget(
              data: RadarChartData(labels: const [], values: profile!.values),
              size: 100,
              fillColor: _accent,
              strokeColor: _accent,
              labelColor: Colors.transparent,
              gridColor: Colors.white12,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personlighetsradar',
                      style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('${(profile!.confidence * 100).toInt()}% tillförlitlighet',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: profile!.confidence,
                      backgroundColor: Colors.white10,
                      color: _accent,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accent.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.radar, color: _accent, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upptäck din personlighetsradar',
                      style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 2),
                  Text('Svara på kompatibilitetsfrågor för att se din profil.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.add_circle_outline, color: _accent),
          ],
        ),
      ),
    );
  }
}
