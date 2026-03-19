import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';

/// Match Preferences Screen (ONB-100)
/// Who do you want to match with? Select gender preferences.
class MatchPreferencesScreen extends StatefulWidget {
  const MatchPreferencesScreen({super.key});

  @override
  State<MatchPreferencesScreen> createState() => _MatchPreferencesScreenState();
}

class _MatchPreferencesScreenState extends State<MatchPreferencesScreen> {
  String? _selected;

  static const _options = ['Men', 'Women', 'Everyone'];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'screen:onboarding-match-preferences',
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
            onPressed: () {
              final d = OnboardingProvider.of(context).data;
              d.preferredGender = 'Everyone';
              d.minAge = 18;
              d.maxAge = 35;
              d.maxDistanceKm = 50;
              OnboardingProvider.of(context).goNext(context);
            },
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
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: OnboardingProvider.of(context).progress(context),
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
                      Text(
                        AppLocalizations.of(context).showMe,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ..._options.map((option) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: () => setState(() => _selected = option),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _selected == option
                                    ? AppTheme.primaryColor
                                    : Colors.grey,
                                width: 2,
                              ),
                              backgroundColor: _selected == option
                                  ? AppTheme.primaryColor.withAlpha(25)
                                  : AppTheme.surfaceColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                            ),
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 18,
                                color: _selected == option
                                    ? AppTheme.primaryColor
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      )),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _selected != null
                              ? () {
                                  OnboardingProvider.of(context).data.preferredGender = _selected;
                                  OnboardingProvider.of(context).goNext(context);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            disabledBackgroundColor: AppTheme.surfaceElevated,
                            disabledForegroundColor: AppTheme.textTertiary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context).nextButton,
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
        ],
      ),
    ),
    );
  }
}
