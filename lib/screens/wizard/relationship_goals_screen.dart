import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';

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
    return Semantics(
      label: 'screen:onboarding-relationship-goals',
      child: Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () { OnboardingProvider.of(context).goNext(context); },
            child: Text(AppLocalizations.of(context).skipButton, style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: OnboardingProvider.of(context).progress(context),
                      backgroundColor: AppTheme.dividerColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    AppLocalizations.of(context).whatAreYouLookingFor,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
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
                                  ? AppTheme.primaryColor.withAlpha(26)
                                  : AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
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
                                    color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
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
                    AppLocalizations.of(context).notShownUnlessYouChoose,
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isValid ? () { OnboardingProvider.of(context).data.relationshipGoal = _selected; OnboardingProvider.of(context).goNext(context); } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.surfaceColor,
                        disabledBackgroundColor: AppTheme.surfaceElevated,
                        disabledForegroundColor: AppTheme.textTertiary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                      ),
                      child: Text(AppLocalizations.of(context).nextButton, style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
