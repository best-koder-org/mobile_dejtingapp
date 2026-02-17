import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/l10n/generated/app_localizations.dart';

void main() {
  group('AppLocalizations', () {
    late AppLocalizations l10n;

    setUp(() async {
      // Load en locale
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('appTitle returns DatingApp', () {
      expect(l10n.appTitle, 'DejTing');
    });

    test('common buttons have correct values', () {
      expect(l10n.continueButton, 'Continue');
      expect(l10n.nextButton, 'Next');
      expect(l10n.cancelButton, 'Cancel');
      expect(l10n.saveButton, 'Save');
      expect(l10n.doneButton, 'Done');
      expect(l10n.skipButton, 'Skip');
      expect(l10n.backButton, 'Back');
      expect(l10n.retryButton, 'Retry');
    });

    test('auth strings are present', () {
      expect(l10n.loginTitle, 'Log In');
      expect(l10n.registerTitle, 'Create Account');
      expect(l10n.logoutConfirmation, contains('logout'));
      expect(l10n.authRequired, 'Authentication required');
      expect(l10n.continueWithApple, 'Continue with Apple');
      expect(l10n.continueWithGoogle, 'Continue with Google');
      expect(l10n.backToLogin, 'Back to login');
    });

    test('onboarding screen titles are present', () {
      expect(l10n.onboardingPhoneTitle, contains('number'));
      expect(l10n.onboardingFirstNameTitle, contains('name'));
      expect(l10n.onboardingBirthdayTitle, contains('birthday'));
      expect(l10n.onboardingGenderTitle, contains('gender'));
      expect(l10n.onboardingOrientationTitle, contains('orientation'));
      expect(l10n.onboardingRelationshipGoalsTitle, contains('looking'));
      expect(l10n.onboardingMatchPrefsTitle, 'Match Preferences');
      expect(l10n.onboardingPhotosTitle, 'Add Photos');
      expect(l10n.onboardingLifestyleTitle, 'Lifestyle');
      expect(l10n.onboardingInterestsTitle, 'Interests');
      expect(l10n.onboardingAboutMeTitle, 'About me');
    });

    test('location permission strings are present', () {
      expect(l10n.onboardingLocationTitle, 'Enable Location');
      expect(l10n.onboardingLocationSubtitle, contains('location'));
      expect(l10n.enableLocationButton, 'Enable Location');
      expect(l10n.maybeLaterButton, 'Maybe Later');
    });

    test('notification permission strings are present', () {
      expect(l10n.onboardingNotificationsTitle, 'Enable Notifications');
      expect(l10n.onboardingNotificationsSubtitle, contains('notified'));
      expect(l10n.enableNotificationsButton, 'Enable Notifications');
    });

    test('onboarding complete strings are present', () {
      expect(l10n.onboardingCompleteTitle, contains('Set'));
      expect(l10n.onboardingCompleteSubtitle, contains('profile'));
      expect(l10n.startDiscoveringButton, 'Start Discovering');
    });

    test('parameterized string — onboardingCodeResent', () {
      final result = l10n.onboardingCodeResent(2);
      expect(result, contains('2'));
      expect(result, contains('left'));
    });

    test('parameterized string — ageRangeLabel', () {
      final result = l10n.ageRangeLabel(18, 35);
      expect(result, contains('18'));
      expect(result, contains('35'));
    });

    test('parameterized string — photoAdded', () {
      final result = l10n.photoAdded(3);
      expect(result, contains('3'));
    });

    test('parameterized string — addUpToInterests', () {
      final result = l10n.addUpToInterests(10);
      expect(result, contains('10'));
    });

    test('navigation tab labels are present', () {
      expect(l10n.profileTab, 'Profile');
      expect(l10n.navMatches, 'Matches');
      expect(l10n.messagesTab, 'Messages');
      expect(l10n.settingsTab, 'Settings');
    });

    test('error messages are present', () {
      expect(l10n.errorGeneric, contains('wrong'));
      expect(l10n.errorNetworkUnavailable, contains('Network'));
      expect(l10n.errorSessionExpired, contains('expired'));
      expect(l10n.errorFieldRequired, contains('required'));
    });

    test('safety strings are present', () {
      expect(l10n.blockUser, 'Block User');
      expect(l10n.reportUser, 'Report User');
    });

    test('supportedLocales contains en', () {
      expect(
        AppLocalizations.supportedLocales,
        contains(const Locale('en')),
      );
    });

    test('localizationsDelegates is not empty', () {
      expect(AppLocalizations.localizationsDelegates, isNotEmpty);
    });
  });
}
