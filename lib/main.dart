import "package:dejtingapp/l10n/generated/app_localizations.dart";
import 'package:flutter/material.dart';
import 'package:dejtingapp/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'main_app.dart';
import 'screens/auth_screens.dart';
import 'screens/photo_upload_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/wizard/phone_entry_screen.dart';
import 'screens/wizard/community_guidelines_screen.dart';
import 'screens/wizard/first_name_screen.dart';
import 'screens/wizard/birthday_screen.dart';
import 'screens/wizard/gender_screen.dart';
import 'screens/wizard/orientation_screen.dart';
import 'screens/wizard/relationship_goals_screen.dart';
import 'screens/wizard/match_preferences_screen.dart';
import 'screens/wizard/photos_screen.dart';
import 'screens/wizard/sms_code_screen.dart';
import 'screens/wizard/lifestyle_screen.dart';
import 'screens/wizard/interests_screen.dart';
import 'screens/wizard/aboutme_screen.dart';
import 'screens/wizard/location_permission_screen.dart';
import 'screens/wizard/notification_permission_screen.dart';
import 'screens/wizard/onboarding_complete_screen.dart';

import 'edit_profile_screen.dart';
import 'services/api_service.dart';
import 'config/environment.dart';
import 'config/dev_mode.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'providers/onboarding_provider.dart';
import 'models/onboarding_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase only works on Android/iOS — skip on desktop (dev testing)
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    debugPrint('⚠️ Firebase skipped on \${defaultTargetPlatform.name} (not supported)');
  }
  EnvSwitcher.useDevelopment();

  if (kDebugMode) {
    debugPrint('🚀 Starting DatingApp in ${EnvironmentConfig.settings.name} environment');
    debugPrint('Gateway: ${EnvironmentConfig.settings.gatewayUrl}');
    debugPrint('Keycloak: ${EnvironmentConfig.settings.keycloakUrl}');
    debugPrint('DevMode: ${DevMode.enabled ? "ON" : "OFF"}');
  }

  final appState = AppState();
  await appState.initialize();

  // No auto-login — always show login screen with pre-filled credentials
  if (kDebugMode) {
    debugPrint('👤 Session: ${appState.hasValidAuthSession() ? "VALID" : "NONE"}');
  }

  runApp(const DatingApp());
}

/// Shared wizard data for the entire onboarding flow.
/// Reset when wizard starts, persists across all screens.
final OnboardingData _onboardingData = OnboardingData();

class DatingApp extends StatelessWidget {
  const DatingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      title: 'DatingApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: _getInitialRoute(),
      routes: {
        // Auth routes
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        
        // Welcome / entry point
        '/welcome': (context) => const WelcomeScreen(),
        
        // Onboarding wizard flow
        '/onboarding/phone-entry': (context) => OnboardingProvider(data: _onboardingData, child: const PhoneEntryScreen()),
        '/onboarding/community-guidelines': (context) => OnboardingProvider(data: _onboardingData, child: const CommunityGuidelinesScreen()),
        '/onboarding/first-name': (context) => OnboardingProvider(data: _onboardingData, child: const FirstNameScreen()),
        '/onboarding/birthday': (context) => OnboardingProvider(data: _onboardingData, child: const BirthdayScreen()),
        '/onboarding/gender': (context) => OnboardingProvider(data: _onboardingData, child: const GenderScreen()),
        '/onboarding/orientation': (context) => OnboardingProvider(data: _onboardingData, child: const OrientationScreen()),
        '/onboarding/relationship-goals': (context) => OnboardingProvider(data: _onboardingData, child: const RelationshipGoalsScreen()),
        '/onboarding/match-preferences': (context) => OnboardingProvider(data: _onboardingData, child: const MatchPreferencesScreen()),
        '/onboarding/photos': (context) => OnboardingProvider(data: _onboardingData, child: const PhotosScreen()),
        '/onboarding/verify-code': (context) => OnboardingProvider(data: _onboardingData, child: const SmsCodeScreen()),
        '/onboarding/lifestyle': (context) => OnboardingProvider(data: _onboardingData, child: const LifestyleScreen()),
        '/onboarding/interests': (context) => OnboardingProvider(data: _onboardingData, child: const InterestsScreen()),
        '/onboarding/about-me': (context) => OnboardingProvider(data: _onboardingData, child: const AboutMeScreen()),
        '/onboarding/location': (context) => OnboardingProvider(data: _onboardingData, child: const LocationPermissionScreen()),
        '/onboarding/notifications': (context) => OnboardingProvider(data: _onboardingData, child: const NotificationPermissionScreen()),
        '/onboarding/complete': (context) => OnboardingProvider(data: _onboardingData, child: const OnboardingCompleteScreen()),
        
        // Main app
        '/home': (context) => const MainApp(),
        '/profile': (context) => const EditProfileScreen(isFirstTime: false),
        '/photos': (context) {
          final appState = AppState();
          final token = appState.authToken;
          final userId = int.tryParse(appState.userId ?? '');
          return PhotoUploadScreen(
            authToken: token,
            userId: userId,
            onPhotoRequirementMet: (bool met) {
              if (met) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Photo requirements met!')),
                );
              }
            },
          );
        },
      },
    );
  }

  String _getInitialRoute() {
    final appState = AppState();
    
    // If we have a valid session, go straight to home (Discover)
    if (appState.hasValidAuthSession(gracePeriod: const Duration(minutes: 1))) {
      return '/home';
    }
    
    // Otherwise show login screen (with pre-filled demo credentials in dev mode)
    return '/login';
  }
}
