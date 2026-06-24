import 'package:flutter/material.dart';
import 'package:dejtingapp/services/radar_service.dart';
import 'package:dejtingapp/widgets/radar/radar_chart_widget.dart';

/// Full-screen radar profile visualization.
///
/// Shows the 7-axis radar chart with per-axis detail cards,
/// confidence score, and last-updated timestamp.
class RadarProfileScreen extends StatefulWidget {
  const RadarProfileScreen({super.key});

  @override
  State<RadarProfileScreen> createState() => _RadarProfileScreenState();
}

class _RadarProfileScreenState extends State<RadarProfileScreen> {
  final _svc = RadarService.instance;
  RadarProfileData? _profile;
  bool _loading = true;

  static const _accent = Color(0xFF6B4EFF);
  static const _bg = Color(0xFFF5F0EB);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final profile = await _svc.getMyProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _bg,
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Din personlighetsradar',
            style: TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8B8578)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _profile == null
          ? const Center(child: Text('Ingen radarprofil än.',
              style: TextStyle(color: Color(0xFF8B8578))))
          : RefreshIndicator(
              onRefresh: _load,
              color: _accent,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Radar chart
                  Center(
                    child: RadarChartWidget(
                      data: RadarChartData(
                        labels: const [
                          'Trygghet', 'Energi', 'Öppenhet', 'Värme',
                          'Struktur', 'Intimitet', 'Konflikt',
                        ],
                        values: _profile!.values,
                      ),
                      fillColor: _accent,
                      strokeColor: _accent,
                      size: 300,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Confidence card
                  _ConfidenceCard(confidence: _profile!.confidence),
                  const SizedBox(height: 16),
                  // Axis detail cards
                  ..._buildAxisCards(),
                  const SizedBox(height: 16),
                  // Footer
                  Text(
                    'Uppdaterad ${_formatDate(_profile!.updatedAt)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF8B8578), fontSize: 12),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildAxisCards() {
    final axes = [
      ('Trygghet', 'Emotionell stabilitet', _profile!.emotionalStability, Icons.shield_outlined),
      ('Energi', 'Social energi', _profile!.socialEnergy, Icons.bolt_outlined),
      ('Öppenhet', 'Nyfikenhet & sårbarhet', _profile!.openness, Icons.explore_outlined),
      ('Värme', 'Empati & omtanke', _profile!.warmth, Icons.favorite_outline),
      ('Struktur', 'Ordning & rutiner', _profile!.lifeStructure, Icons.calendar_today_outlined),
      ('Intimitet', 'Närhet & anknytning', _profile!.intimacyComfort, Icons.bedtime_outlined),
      ('Konflikt', 'Konfliktstil', _profile!.conflictStyle, Icons.handshake_outlined),
    ];

    return axes.map((a) => _AxisCard(
      label: a.$1,
      subtitle: a.$2,
      value: a.$3,
      icon: a.$4,
    )).toList();
  }

  static String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ── Confidence card ────────────────────────────────────────────────────

class _ConfidenceCard extends StatelessWidget {
  final double confidence;
  const _ConfidenceCard({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).toInt();
    final label = confidence < 0.5 ? 'Låg tillförlitlighet'
        : confidence < 0.7 ? 'Medel'
        : 'Hög tillförlitlighet';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6B4EFF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.analytics_outlined, color: Color(0xFF6B4EFF), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: confidence,
                    backgroundColor: const Color(0xFFF5F0EB),
                    color: const Color(0xFF6B4EFF),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('$pct%', style: const TextStyle(color: Color(0xFF6B4EFF), fontWeight: FontWeight.bold, fontSize: 20)),
        ],
      ),
    );
  }
}

// ── Per-axis detail card ──────────────────────────────────────────────

class _AxisCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final double value;
  final IconData icon;

  const _AxisCard({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).toInt();
    final color = value > 0.7 ? const Color(0xFF6B8F71)
        : value > 0.4 ? const Color(0xFFD4A76A)
        : const Color(0xFF8B7D6B);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: const TextStyle(color: Color(0xFF8B8578), fontSize: 11)),
              ],
            ),
          ),
          // Mini progress bar
          SizedBox(
            width: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: const Color(0xFFF5F0EB),
                color: color,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text('$pct%',
                textAlign: TextAlign.right,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
