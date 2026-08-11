import 'package:flutter/material.dart';
import 'package:dejtingapp/theme/app_theme.dart';
import 'package:dejtingapp/services/reputation_service.dart';

/// T709 — Feedback prompt that appears after meaningful chat (≥10 messages).
/// Star rating + positive trait selector. Positive-only traits displayed.
class ChatFeedbackPrompt extends StatefulWidget {
  final String targetKeycloakId;
  final String targetName;
  final String matchId;
  final VoidCallback? onSubmitted;

  const ChatFeedbackPrompt({
    super.key,
    required this.targetKeycloakId,
    required this.targetName,
    required this.matchId,
    this.onSubmitted,
  });

  @override
  State<ChatFeedbackPrompt> createState() => _ChatFeedbackPromptState();
}

class _ChatFeedbackPromptState extends State<ChatFeedbackPrompt> {
  final _svc = ReputationService.instance;
  int _rating = 0;
  final Set<String> _selectedTraits = {};
  bool _submitting = false;
  bool _submitted = false;

  static const _traits = [
    _Trait('kind', 'Vänlig', Icons.favorite_outline),
    _Trait('funny', 'Rolig', Icons.emoji_emotions_outlined),
    _Trait('thoughtful', 'Omtänksam', Icons.eco_outlined),
    _Trait('good-listener', 'Bra lyssnare', Icons.hearing_outlined),
    _Trait('interesting', 'Intressant', Icons.lightbulb_outlined),
    _Trait('respectful', 'Respektfull', Icons.handshake_outlined),
    _Trait('honest', 'Ärlig', Icons.shield_outlined),
    _Trait('engaged', 'Engagerad', Icons.rocket_launch_outlined),
    _Trait('positive', 'Positiv energi', Icons.wb_sunny_outlined),
    _Trait('relaxed', 'Avslappnad', Icons.spa_outlined),
  ];

  static const _accent = Color(0xFF6B4EFF);

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _buildSubmitted();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.favorite, color: _accent, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Vad tyckte du om samtalet?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D))),
            ),
          ]),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text('Berätta för ${widget.targetName} vad du uppskattade.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8B8578))),
          ),
          const SizedBox(height: 14),

          // Star rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    color: star <= _rating ? const Color(0xFFFFD700) : const Color(0xFFD0C8E0),
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              _rating == 0 ? 'Tryck för att betygsätta' :
              _rating <= 2 ? 'Tråkigt att höra' :
              _rating == 3 ? 'Bra!' :
              'Underbart! 🎉',
              style: const TextStyle(color: Color(0xFF8B8578), fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 14),

          // Trait selector (only show if rating ≥ 3)
          if (_rating >= 3) ...[
            const Text('Vad uppskattade du? (välj max 3)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _traits.map((t) {
                final selected = _selectedTraits.contains(t.key);
                return GestureDetector(
                  onTap: () {
                    if (selected) {
                      setState(() => _selectedTraits.remove(t.key));
                    } else if (_selectedTraits.length < 3) {
                      setState(() => _selectedTraits.add(t.key));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected ? _accent : _accent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? _accent : _accent.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(t.label,
                        style: TextStyle(
                          color: selected ? Colors.white : _accent,
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_rating > 0 && !_submitting) ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _submitting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Skicka feedback', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),

          // Skip link
          Center(
            child: TextButton(
              onPressed: () => setState(() => _submitted = true),
              child: const Text('Hoppa över', style: TextStyle(color: Color(0xFF8B8578), fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await _svc.submitFeedback(
      targetKeycloakId: widget.targetKeycloakId,
      matchId: widget.matchId,
      overallRating: _rating,
      selectedTraits: _selectedTraits.toList(),
      feedbackType: 'chat',
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submitted = true;
    });
    widget.onSubmitted?.call();
  }

  Widget _buildSubmitted() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6B8F71).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF6B8F71), size: 24),
          const SizedBox(width: 10),
          const Text('Tack för din feedback!',
              style: TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

class _Trait {
  final String key;
  final String label;
  final IconData icon;
  const _Trait(this.key, this.label, this.icon);
}
