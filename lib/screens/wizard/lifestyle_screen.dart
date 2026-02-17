import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/dev_mode_banner.dart';
import '../../providers/onboarding_provider.dart';

/// Lifestyle Habits Screen — Smoking, Exercise, Pets
/// Optional screen that contributes to profile completeness %
class LifestyleScreen extends StatefulWidget {
  const LifestyleScreen({super.key});

  @override
  State<LifestyleScreen> createState() => _LifestyleScreenState();
}

class _LifestyleScreenState extends State<LifestyleScreen> {
  static const Color _coral = Color(0xFFFF6B6B);

  // Selected values (null = not answered)
  String? _smoking;
  String? _exercise;
  String? _pets;

  static const _smokingOptions = [
    'Social smoker',
    'Smoker when drinking',
    'Non-smoker',
    'Smoker',
    'Trying to quit',
  ];

  static const _exerciseOptions = [
    'Every day',
    'Often',
    'Sometimes',
    'Never',
  ];

  static const _petOptions = [
    'Dog',
    'Cat',
    'Reptile',
    'Amphibian',
    'Bird',
    'Fish',
    "Don't have but love",
    'Other',
    'Turtle',
    'Hamster',
    'Rabbit',
    'Pet-free',
  ];

  void _continue() {
    final _d = OnboardingProvider.of(context).data; final _m = <String, String>{}; if (_smoking != null) _m['smoking'] = _smoking!; if (_exercise != null) _m['exercise'] = _exercise!; if (_pets != null) _m['pets'] = _pets!; _d.lifestyle = _m;

    OnboardingProvider.of(context).goNext(context);
  }

  void _skip() {
    final _d = OnboardingProvider.of(context).data; final _m = <String, String>{}; if (_smoking != null) _m['smoking'] = _smoking!; if (_exercise != null) _m['exercise'] = _exercise!; if (_pets != null) _m['pets'] = _pets!; _d.lifestyle = _m;

    OnboardingProvider.of(context).goNext(context);
  }

  Widget _buildSection({
    required String emoji,
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected == option;
            return GestureDetector(
              onTap: () => onSelected(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _coral
                      : Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? _coral
                        : Colors.white.withAlpha(51),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAnySelection =
        _smoking != null || _exercise != null || _pets != null;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _skip,
            child: Text(
              AppLocalizations.of(context)!.skipButton,
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
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
                      valueColor: const AlwaysStoppedAnimation(_coral),
                      minHeight: 4,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.lifestyleHabits,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.lifestyleSubtitle,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withAlpha(153),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Smoking
                        _buildSection(
                          emoji: '🚬',
                          title: 'How often do you smoke?',
                          options: _smokingOptions,
                          selected: _smoking,
                          onSelected: (v) =>
                              setState(() => _smoking = _smoking == v ? null : v),
                        ),
                        const SizedBox(height: 28),

                        // Exercise
                        _buildSection(
                          emoji: '💪',
                          title: 'Do you exercise?',
                          options: _exerciseOptions,
                          selected: _exercise,
                          onSelected: (v) => setState(
                              () => _exercise = _exercise == v ? null : v),
                        ),
                        const SizedBox(height: 28),

                        // Pets
                        _buildSection(
                          emoji: '🐾',
                          title: 'Do you have any pets?',
                          options: _petOptions,
                          selected: _pets,
                          onSelected: (v) =>
                              setState(() => _pets = _pets == v ? null : v),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                // Continue button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            hasAnySelection ? _coral : _coral.withAlpha(102),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        hasAnySelection ? AppLocalizations.of(context)!.continueButton : AppLocalizations.of(context)!.skipForNow,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          DevModeSkipButton(
            onSkip: _skip,
            label: 'Skip Lifestyle',
          ),
        ],
      ),
    );
  }
}
