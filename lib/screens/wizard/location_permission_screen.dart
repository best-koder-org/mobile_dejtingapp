import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/dev_mode_banner.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';

/// Location Permission Screen (T026 gap)
/// Asks user to enable location services for distance-based matching.
class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'screen:onboarding-location',
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        AppLocalizations.of(context).enableLocation,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).locationDescription,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () async {
                            final status = await Permission.locationWhenInUse.request();
                            if (!context.mounted) return;
                            OnboardingProvider.of(context).data.locationGranted = status.isGranted;
                            OnboardingProvider.of(context).goNext(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context).enableLocationBtn,
                            style: TextStyle(fontSize: 18, color: AppTheme.textOnPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          OnboardingProvider.of(context).data.locationGranted = true;
                          OnboardingProvider.of(context).goNext(context);
                        },
                        child: Text(
                          AppLocalizations.of(context).notNow,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
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
          DevModeSkipButton(
            onSkip: () { OnboardingProvider.of(context).data.locationGranted = false; OnboardingProvider.of(context).goNext(context); },
            label: 'Skip Location',
          ),
        ],
      ),
    ),
    );
  }
}
