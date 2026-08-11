import 'package:flutter/material.dart';
import 'package:dejtingapp/services/reputation_service.dart';

/// T710 — Displays earned trait badges on a user's profile.
/// Traits shown are those with ≥3 confirmations from different users.
class TraitBadgesWidget extends StatefulWidget {
  final String keycloakId;

  const TraitBadgesWidget({super.key, required this.keycloakId});

  @override
  State<TraitBadgesWidget> createState() => _TraitBadgesWidgetState();
}

class _TraitBadgesWidgetState extends State<TraitBadgesWidget> {
  final _svc = ReputationService.instance;
  List<String> _traits = [];
  int _totalRatings = 0;
  bool _loading = true;

  static const _traitMeta = {
    'kind':      _TraitMetaData('Vänlig',     Icons.favorite_outline,        Color(0xFFE74C3C)),
    'funny':     _TraitMetaData('Rolig',      Icons.emoji_emotions_outlined, Color(0xFFF39C12)),
    'thoughtful':_TraitMetaData('Omtänksam',  Icons.eco_outlined,           Color(0xFF27AE60)),
    'good-listener':_TraitMetaData('Bra lyssnare',Icons.hearing_outlined,   Color(0xFF3498DB)),
    'interesting':_TraitMetaData('Intressant',Icons.lightbulb_outlined,     Color(0xFF9B59B6)),
    'respectful':_TraitMetaData('Respektfull',Icons.handshake_outlined,     Color(0xFF1ABC9C)),
    'honest':    _TraitMetaData('Ärlig',      Icons.shield_outlined,        Color(0xFF2C3E50)),
    'engaged':   _TraitMetaData('Engagerad',  Icons.rocket_launch_outlined, Color(0xFFE67E22)),
    'positive':  _TraitMetaData('Positiv',    Icons.wb_sunny_outlined,      Color(0xFFF1C40F)),
    'relaxed':   _TraitMetaData('Avslappnad', Icons.spa_outlined,           Color(0xFF8E44AD)),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _svc.getTraits(widget.keycloakId);
    if (!mounted) return;
    setState(() {
      if (data != null) {
        _traits = List<String>.from(data['traits'] as List? ?? []);
        _totalRatings = data['totalRatings'] as int? ?? 0;
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_traits.isEmpty && _totalRatings == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_traits.isNotEmpty) ...[
          const Text('Omdömen från matchningar',
              style: TextStyle(color: Color(0xFF8B8578), fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _traits.map((t) {
              final meta = _traitMeta[t];
              if (meta == null) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: meta.color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(meta.icon, size: 12, color: meta.color),
                    const SizedBox(width: 4),
                    Text(meta.label,
                        style: TextStyle(color: meta.color, fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
        if (_totalRatings > 0 && _traits.isEmpty)
          Text('$_totalRatings omdömen — inga offentliga badges än',
              style: const TextStyle(color: Color(0xFF8B8578), fontSize: 11, fontStyle: FontStyle.italic)),
      ],
    );
  }
}

class _TraitMetaData {
  final String label;
  final IconData icon;
  final Color color;
  const _TraitMetaData(this.label, this.icon, this.color);
}
