import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';

/// Notification Permission Screen (T026 gap)
/// Asks user to enable push notifications for matches and messages.
class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          TextButton(
            onPressed: () { OnboardingProvider.of(context).data.notificationsGranted = false; OnboardingProvider.of(context).goNext(context); },
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        AppLocalizations.of(context).enableNotifications,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context).neverMissAMatch,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).notificationDescription,
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
                            final status = await Permission.notification.request();
                            if (!context.mounted) return;
                            OnboardingProvider.of(context).data.notificationsGranted = status.isGranted;
                            OnboardingProvider.of(context).goNext(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context).enableNotificationsBtn,
                            style: TextStyle(fontSize: 18, color: AppTheme.textOnPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          OnboardingProvider.of(context).data.notificationsGranted = true;
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
        ],
      ),
    );
  }
}
