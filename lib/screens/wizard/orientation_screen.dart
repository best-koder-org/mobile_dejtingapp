import 'package:flutter/material.dart';
import '../../widgets/dev_mode_banner.dart';
import '../../providers/onboarding_provider.dart';

/// Sexual Orientation Screen — Tinder-style card list with descriptions
class OrientationScreen extends StatefulWidget {
  const OrientationScreen({super.key});

  @override
  State<OrientationScreen> createState() => _OrientationScreenState();
}

class _OrientationScreenState extends State<OrientationScreen> {
  final Set<String> _selected = {};
  bool _showOnProfile = false;
  static const int _maxSelections = 3;

  // Each orientation with a short description (like Tinder's UI)
  static const List<Map<String, String>> _orientations = [
    {
      'label': 'Straight',
      'desc': 'A person who is exclusively attracted to members of the opposite gender',
    },
    {
      'label': 'Gay',
      'desc': 'An umbrella term used to describe someone who is attracted to members of their gender',
    },
    {
      'label': 'Lesbian',
      'desc': 'A woman who is emotionally, romantically, or sexually attracted to other women and non-binary people',
    },
    {
      'label': 'Bisexual',
      'desc': 'A person who has potential for emotional, romantic, or sexual attraction to people of more than one gender',
    },
    {
      'label': 'Asexual',
      'desc': 'A person who experiences little or no sexual attraction to others',
    },
    {
      'label': 'Demisexual',
      'desc': 'A person who only experiences sexual attraction after forming a strong emotional bond',
    },
    {
      'label': 'Pansexual',
      'desc': 'A person who can experience attraction to people regardless of their gender',
    },
    {
      'label': 'Queer',
      'desc': 'An umbrella term for people who are not heterosexual or cisgender',
    },
    {
      'label': 'Questioning',
      'desc': 'A person who is exploring or unsure of their sexual orientation',
    },
  ];

  bool get _isValid => _selected.isNotEmpty;

  void _toggleOrientation(String orientation) {
    setState(() {
      if (_selected.contains(orientation)) {
        _selected.remove(orientation);
      } else if (_selected.length < _maxSelections) {
        _selected.add(orientation);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () =>
                OnboardingProvider.of(context).abort(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: OnboardingProvider.of(context).progress(context),
                      backgroundColor: Colors.white.withAlpha(51),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF6B6B)),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "What's your sexual\norientation?",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select all that describe you to reflect your identity.',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey[400]),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _orientations.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final o = _orientations[index];
                      final label = o['label']!;
                      final desc = o['desc']!;
                      final isSelected = _selected.contains(label);
                      final canSelect =
                          _selected.length < _maxSelections || isSelected;

                      return GestureDetector(
                        onTap: canSelect
                            ? () => _toggleOrientation(label)
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFF6B6B).withAlpha(20)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF6B6B)
                                  : Colors.grey[700]!,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      desc,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[500],
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 12),
                                const Icon(Icons.check_circle,
                                    color: Color(0xFFFF6B6B), size: 24),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _showOnProfile,
                        onChanged: (v) =>
                            setState(() => _showOnProfile = v ?? false),
                        activeColor: const Color(0xFFFF6B6B),
                        checkColor: Colors.white,
                        side: BorderSide(color: Colors.grey[600]!),
                      ),
                      Expanded(
                        child: Text(
                          'Show my orientation on my profile',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[400]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isValid
                          ? () { final _d = OnboardingProvider.of(context).data; _d.orientation = _selected.toList(); _d.orientationVisible = _showOnProfile; OnboardingProvider.of(context).goNext(context); }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[700],
                        disabledForegroundColor: Colors.grey[500],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26)),
                      ),
                      child: const Text('Next',
                          style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          DevModeSkipButton(
            onSkip: () => OnboardingProvider.of(context).goNext(context),
            label: 'Skip Orientation',
          ),
        ],
      ),
    );
  }
}
