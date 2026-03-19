import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';

/// Sexual Orientation Screen
///
/// Orientation combos logic (industry-standard, matches Tinder/Bumble/Hinge):
/// - "Primary" group: Straight, Gay, Lesbian — mutually exclusive (pick max 1)
/// - "Spectrum" group: Bisexual, Pansexual, Queer, Questioning, Asexual, Demisexual
///   — can combine freely with each other + with 1 primary label
/// - Max 3 total selections
class OrientationScreen extends StatefulWidget {
  const OrientationScreen({super.key});

  @override
  State<OrientationScreen> createState() => _OrientationScreenState();
}

class _OrientationScreenState extends State<OrientationScreen> {
  final Set<String> _selected = {};
  bool _showOnProfile = false;
  static const int _maxSelections = 3;

  /// Primary attraction labels — mutually exclusive with each other.
  static const Set<String> _primaryGroup = {'Straight', 'Gay', 'Lesbian'};

  static const List<String> _orientationLabels = [
    'Straight', 'Gay', 'Lesbian', 'Bisexual', 'Asexual',
    'Demisexual', 'Pansexual', 'Queer', 'Questioning',
  ];

  bool get _isValid => _selected.isNotEmpty;

  void _toggleOrientation(String orientation) {
    setState(() {
      if (_selected.contains(orientation)) {
        // Deselect
        _selected.remove(orientation);
      } else if (_selected.length < _maxSelections) {
        // If selecting a primary label, remove any other primary first
        if (_primaryGroup.contains(orientation)) {
          _selected.removeWhere((s) => _primaryGroup.contains(s));
        }
        _selected.add(orientation);
      }
    });
  }

  /// Whether this option can be tapped right now.
  bool _canSelect(String label) {
    if (_selected.contains(label)) return true; // can always deselect
    if (_selected.length >= _maxSelections) return false;
    // If selecting a primary and already have one, we'll swap — allow it
    if (_primaryGroup.contains(label)) return true;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final descMap = <String, String>{
      'Straight': l10n.orientationStraightDesc,
      'Gay': l10n.orientationGayDesc,
      'Lesbian': l10n.orientationLesbianDesc,
      'Bisexual': l10n.orientationBisexualDesc,
      'Asexual': l10n.orientationAsexualDesc,
      'Demisexual': l10n.orientationDemisexualDesc,
      'Pansexual': l10n.orientationPansexualDesc,
      'Queer': l10n.orientationQueerDesc,
      'Questioning': l10n.orientationQuestioningDesc,
    };

    return Semantics(
      label: 'screen:onboarding-orientation',
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
            onPressed: () => OnboardingProvider.of(context).goNext(context),
            child: Text(l10n.skipButton,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textPrimary),
            onPressed: () => OnboardingProvider.of(context).abort(context),
          ),
        ],
      ),
      body: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: OnboardingProvider.of(context).progress(context),
              backgroundColor: AppTheme.dividerColor,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              minHeight: 4,
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    l10n.whatsYourOrientation,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.selectOrientations,
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _orientationLabels.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final label = _orientationLabels[index];
                        final desc = descMap[label] ?? '';
                        final isSelected = _selected.contains(label);
                        final canSelect = _canSelect(label);

                        return GestureDetector(
                          onTap: canSelect
                              ? () => _toggleOrientation(label)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor.withAlpha(25)
                                  : AppTheme.surfaceColor,
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : canSelect
                                        ? AppTheme.dividerColor
                                        : AppTheme.dividerColor,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Opacity(
                              opacity: canSelect ? 1.0 : 0.4,
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
                                                ? AppTheme.primaryColor
                                                : AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          desc,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textSecondary,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 12),
                                    const Icon(Icons.check_circle,
                                        color: AppTheme.primaryColor, size: 24),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _showOnProfile,
                        onChanged: (v) =>
                            setState(() => _showOnProfile = v ?? false),
                        activeColor: AppTheme.primaryColor,
                      ),
                      Expanded(
                        child: Text(
                          l10n.showOrientationOnProfile,
                          style:
                              TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Next button — always visible, dimmed when no selection
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isValid
                          ? () {
                              final d = OnboardingProvider.of(context).data;
                              d.orientation = _selected.toList();
                              d.orientationVisible = _showOnProfile;
                              OnboardingProvider.of(context).goNext(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        disabledBackgroundColor: AppTheme.surfaceElevated,
                        disabledForegroundColor: AppTheme.textTertiary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27)),
                      ),
                      child: Text(
                        l10n.nextButton,
                        style:
                            const TextStyle(fontSize: 18, color: AppTheme.textOnPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
    ),
    );
  }
}
