import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';

/// Lifestyle Habits Screen — Smoking, Exercise, Pets
/// Optional screen that contributes to profile completeness %
class LifestyleScreen extends StatefulWidget {
  const LifestyleScreen({super.key});

  @override
  State<LifestyleScreen> createState() => _LifestyleScreenState();
}

class _LifestyleScreenState extends State<LifestyleScreen> {

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
    final d = OnboardingProvider.of(context).data; final m = <String, String>{}; if (_smoking != null) m['smoking'] = _smoking!; if (_exercise != null) m['exercise'] = _exercise!; if (_pets != null) m['pets'] = _pets!; d.lifestyle = m;

    OnboardingProvider.of(context).goNext(context);
  }

  void _skip() {
    final d = OnboardingProvider.of(context).data; final m = <String, String>{}; if (_smoking != null) m['smoking'] = _smoking!; if (_exercise != null) m['exercise'] = _exercise!; if (_pets != null) m['pets'] = _pets!; d.lifestyle = m;

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
                  color: AppTheme.textPrimary,
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
                      ? AppTheme.primaryColor
                      : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.dividerColor,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? AppTheme.textOnPrimary : AppTheme.textPrimary,
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

    return Semantics(
      label: 'screen:onboarding-lifestyle',
      child: Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _skip,
            child: Text(
              AppLocalizations.of(context).skipButton,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textPrimary),
            onPressed: () => OnboardingProvider.of(context).abort(context),
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
                      backgroundColor: AppTheme.dividerColor,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
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
                          AppLocalizations.of(context).lifestyleHabits,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context).lifestyleSubtitle,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Smoking
                        _buildSection(
                          emoji: '🚬',
                          title: AppLocalizations.of(context).lifestyleSmokingTitle,
                          options: _smokingOptions,
                          selected: _smoking,
                          onSelected: (v) =>
                              setState(() => _smoking = _smoking == v ? null : v),
                        ),
                        const SizedBox(height: 28),

                        // Exercise
                        _buildSection(
                          emoji: '💪',
                          title: AppLocalizations.of(context).lifestyleExerciseTitle,
                          options: _exerciseOptions,
                          selected: _exercise,
                          onSelected: (v) => setState(
                              () => _exercise = _exercise == v ? null : v),
                        ),
                        const SizedBox(height: 28),

                        // Pets
                        _buildSection(
                          emoji: '🐾',
                          title: AppLocalizations.of(context).lifestylePetsTitle,
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
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            hasAnySelection ? AppTheme.primaryColor : AppTheme.primaryColor.withAlpha(102),
                        foregroundColor: AppTheme.surfaceColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        hasAnySelection ? AppLocalizations.of(context).continueButton : AppLocalizations.of(context).skipForNow,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
