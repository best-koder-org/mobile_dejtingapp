import 'package:flutter/material.dart';
import '../../widgets/dev_mode_banner.dart';
import '../../providers/onboarding_provider.dart';

/// Relationship Goals Screen (ONB-110)
/// Card grid with emoji + label, single selection
class RelationshipGoalsScreen extends StatefulWidget {
  const RelationshipGoalsScreen({super.key});

  @override
  State<RelationshipGoalsScreen> createState() => _RelationshipGoalsScreenState();
}

class _RelationshipGoalsScreenState extends State<RelationshipGoalsScreen> {
  String? _selected;

  static const List<Map<String, String>> _goals = [
    {'emoji': '💑', 'label': 'Long-term partner'},
    {'emoji': '🌊', 'label': 'Long-term, open to short'},
    {'emoji': '🎯', 'label': 'Short-term, open to long'},
    {'emoji': '🎉', 'label': 'Short-term fun'},
    {'emoji': '👋', 'label': 'New friends'},
    {'emoji': '🤔', 'label': 'Still figuring it out'},
  ];

  bool get _isValid => _selected != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => OnboardingProvider.of(context).abort(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: OnboardingProvider.of(context).progress(context),
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'What are you\nlooking for?',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: _goals.map((goal) {
                        final isSelected = _selected == goal['label'];
                        return GestureDetector(
                          onTap: () => setState(() => _selected = goal['label']),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFF6B6B).withAlpha(26)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFFF6B6B) : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(goal['emoji']!, style: const TextStyle(fontSize: 32)),
                                const SizedBox(height: 8),
                                Text(
                                  goal['label']!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected ? const Color(0xFFFF6B6B) : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Text(
                    'Not shown on profile unless you choose',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isValid ? () { OnboardingProvider.of(context).data.relationshipGoal = _selected; OnboardingProvider.of(context).goNext(context); } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                      child: const Text('Next', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          DevModeSkipButton(
            onSkip: () { OnboardingProvider.of(context).data.relationshipGoal = _selected; OnboardingProvider.of(context).goNext(context); },
            label: 'Skip Goals',
          ),
        ],
      ),
    );
  }
}
