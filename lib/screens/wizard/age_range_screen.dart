import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';

/// Age Range Preference Screen — consistent white-background style
class AgeRangeScreen extends StatefulWidget {
  const AgeRangeScreen({super.key});

  @override
  State<AgeRangeScreen> createState() => _AgeRangeScreenState();
}

class _AgeRangeScreenState extends State<AgeRangeScreen> {
  static const double _minAllowed = 18;
  static const double _maxAllowed = 100;
  

  late RangeValues _range;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final data = OnboardingProvider.of(context).data;
    _range = RangeValues(
      data.minAge.toDouble().clamp(_minAllowed, _maxAllowed),
      data.maxAge.toDouble().clamp(_minAllowed, _maxAllowed),
    );
  }

  void _onNext() {
    final onboarding = OnboardingProvider.of(context);
    onboarding.data.minAge = _range.start.round();
    onboarding.data.maxAge = _range.end.round();
    onboarding.goNext(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onboarding = OnboardingProvider.of(context);
    final startAge = _range.start.round();
    final endAge = _range.end.round();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textPrimary),
            onPressed: () => onboarding.abort(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: onboarding.progress(context),
              backgroundColor: AppTheme.dividerColor,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
              minHeight: 4,
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    l10n.ageRangeTitle,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Age range display
                  Center(
                    child: Text(
                      '$startAge – $endAge',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      l10n.yearsOld,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Range slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primaryColor,
                      inactiveTrackColor: AppTheme.dividerColor,
                      thumbColor: AppTheme.primaryColor,
                      overlayColor: AppTheme.primaryColor.withAlpha(40),
                      trackHeight: 4,
                      showValueIndicator: ShowValueIndicator.never,
                      rangeThumbShape: const RoundRangeSliderThumbShape(
                        enabledThumbRadius: 14,
                        elevation: 4,
                      ),
                    ),
                    child: RangeSlider(
                      values: _range,
                      min: _minAllowed,
                      max: _maxAllowed,
                      divisions: (_maxAllowed - _minAllowed).round(),
                      onChanged: (values) {
                        setState(() => _range = values);
                      },
                    ),
                  ),

                  // Min / Max labels
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_minAllowed.round()}',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                        Text('${_maxAllowed.round()}',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Bottom hints
                  Row(
                    children: [
                      Icon(Icons.tune, color: AppTheme.textSecondary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.editableInSettings,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.visibility_off, color: AppTheme.textSecondary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.notVisibleOnProfile,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Next button — full width, always visible
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.surfaceColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                      ),
                      child: Text(
                        l10n.nextButton,
                        style: TextStyle(fontSize: 18, color: AppTheme.textOnPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}
