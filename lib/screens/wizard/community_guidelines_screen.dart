import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';

/// Community Guidelines Screen
/// Shows house rules that users must accept before proceeding
class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'screen:onboarding-community-guidelines',
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: OnboardingProvider.of(context).progress(context),
                      backgroundColor: AppTheme.dividerColor,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                      minHeight: 4,
                    ),
                  ),
                  SizedBox(height: 32),

                  Text(
                    AppLocalizations.of(context).welcomeToDejTing,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, height: 1.2),
                  ),
                  SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).followHouseRules,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 40),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildRule(AppLocalizations.of(context).ruleBeYourself, AppLocalizations.of(context).ruleBeYourselfDesc),
                          const SizedBox(height: 28),
                          _buildRule(AppLocalizations.of(context).ruleStaySafe, AppLocalizations.of(context).ruleStaySafeDesc),
                          const SizedBox(height: 28),
                          _buildRule(AppLocalizations.of(context).rulePlayItCool, AppLocalizations.of(context).rulePlayItCoolDesc),
                          const SizedBox(height: 28),
                          _buildRule(AppLocalizations.of(context).ruleBeProactive, AppLocalizations.of(context).ruleBeProactiveDesc),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {  OnboardingProvider.of(context).goNext(context); },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.scaffoldDark,
                        foregroundColor: AppTheme.textPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                          side: const BorderSide(color: AppTheme.textPrimary, width: 2),
                        ),
                      ),
                      child: Text(AppLocalizations.of(context).iAgreeButton, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildRule(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(color: Color(0xFF00C878), shape: BoxShape.circle),
          child: const Icon(Icons.check, color: AppTheme.textOnPrimary, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary, height: 1.3)),
              const SizedBox(height: 4),
              Text(description, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppTheme.textSecondary, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
