import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';

/// About Me Screen — Communication style, Love language, Education
/// "What else makes you, you?" — optional profile enrichment
class AboutMeScreen extends StatefulWidget {
  const AboutMeScreen({super.key});

  @override
  State<AboutMeScreen> createState() => _AboutMeScreenState();
}

class _AboutMeScreenState extends State<AboutMeScreen> {

  // Single-select per section
  String? _communicationStyle;
  String? _loveLanguage;
  String? _education;

  static const _communicationOptions = [
    'Big time texter',
    'Phone caller',
    'Video chatter',
    'Bad texter',
    'Better in person',
  ];

  static const _loveLanguageOptions = [
    'Thoughtful gestures',
    'Presents',
    'Touch',
    'Compliments',
    'Time together',
  ];

  static const _educationOptions = [
    'High school',
    'At uni',
    'Undergraduate degree',
    "Bachelor's degree",
    "Master's degree",
    'PhD',
    'Trade school',
  ];

  void _finish() {
    final d = OnboardingProvider.of(context).data; d.communicationStyle = _communicationStyle; d.loveLanguage = _loveLanguage; d.education = _education; OnboardingProvider.of(context).goNext(context);
  }

  void _skip() {
    final d = OnboardingProvider.of(context).data; d.communicationStyle = _communicationStyle; d.loveLanguage = _loveLanguage; d.education = _education; OnboardingProvider.of(context).goNext(context);
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
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
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
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
    final hasAnySelection = _communicationStyle != null ||
        _loveLanguage != null ||
        _education != null;

    return Semantics(
      label: 'screen:onboarding-about-me',
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
                          AppLocalizations.of(context).whatMakesYouYou,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context).authenticitySubtitle,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Communication style
                        _buildSection(
                          emoji: '📝',
                          title: AppLocalizations.of(context).aboutMeCommunicationStyle,
                          options: _communicationOptions,
                          selected: _communicationStyle,
                          onSelected: (v) => setState(() =>
                              _communicationStyle =
                                  _communicationStyle == v ? null : v),
                        ),
                        const SizedBox(height: 28),

                        // Love language
                        _buildSection(
                          emoji: '❤️',
                          title: AppLocalizations.of(context).aboutMeLoveLanguage,
                          options: _loveLanguageOptions,
                          selected: _loveLanguage,
                          onSelected: (v) => setState(() =>
                              _loveLanguage = _loveLanguage == v ? null : v),
                        ),
                        const SizedBox(height: 28),

                        // Education
                        _buildSection(
                          emoji: '🎓',
                          title: AppLocalizations.of(context).aboutMeEducationLevel,
                          options: _educationOptions,
                          selected: _education,
                          onSelected: (v) => setState(() =>
                              _education = _education == v ? null : v),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                // Finish button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _finish,
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
                        hasAnySelection
                            ? AppLocalizations.of(context).letsGo
                            : AppLocalizations.of(context).skipAndFinish,
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
