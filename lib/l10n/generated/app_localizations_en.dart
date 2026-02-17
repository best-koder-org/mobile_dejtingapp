// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DejTing';

  @override
  String get appName => 'DejTing';

  @override
  String get continueButton => 'Continue';

  @override
  String get nextButton => 'Next';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get saveButton => 'Save';

  @override
  String get doneButton => 'Done';

  @override
  String get skipButton => 'Skip';

  @override
  String get backButton => 'Back';

  @override
  String get retryButton => 'Retry';

  @override
  String get okButton => 'OK';

  @override
  String get deleteButton => 'Delete';

  @override
  String get reportButton => 'Report';

  @override
  String get blockButton => 'Block';

  @override
  String get gotItButton => 'Got it';

  @override
  String get closeButton => 'Close';

  @override
  String get goBackButton => 'Go back';

  @override
  String get tryAgainButton => 'Try Again';

  @override
  String get refreshButton => 'Refresh';

  @override
  String get upgradeButton => 'Upgrade';

  @override
  String get manageButton => 'Manage';

  @override
  String get unblockButton => 'Unblock';

  @override
  String get logoutButton => 'Logout';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get notNow => 'Not now';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get orDivider => 'or';

  @override
  String get navDiscover => 'Discover';

  @override
  String get navMatches => 'Matches';

  @override
  String get navProfile => 'Profile';

  @override
  String get loginTitle => 'Log In';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get loginTagline => 'Find your perfect match';

  @override
  String get noPasswordsNeeded => 'No passwords needed';

  @override
  String get phoneSignInDescription =>
      'Sign in with your phone number.\nWe\'ll text you a verification code.';

  @override
  String get continueWithPhone => 'Continue with Phone Number';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get signInWithBrowser => 'Sign in with Browser';

  @override
  String get signInWithPhone => 'Sign in with phone number';

  @override
  String get browserLoginFailed => 'Browser login failed. Please try again.';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get troubleLoggingIn => 'Trouble Logging In?';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get authRequired => 'Authentication required';

  @override
  String get authRequiredDetail =>
      'Authentication required. Please log in again.';

  @override
  String get createAccount => 'Create account';

  @override
  String get termsIntro => 'By tapping Log In or Continue, you agree to our ';

  @override
  String get termsLink => 'Terms';

  @override
  String get privacyIntro => '. Learn how we process your data in our ';

  @override
  String get privacyPolicyLink => 'Privacy Policy';

  @override
  String get onboardingPhoneTitle => 'Can we get your number?';

  @override
  String get phoneVerificationExplainer =>
      'We\'ll send you a text with a verification code. Message and data rates may apply.';

  @override
  String get phoneNumberHint => 'Phone number';

  @override
  String get phoneVerificationMobileOnly =>
      'Phone verification requires a mobile device (Android/iOS).';

  @override
  String get failedToSendCode =>
      'Failed to send verification code. Please try again.';

  @override
  String get selectCountry => 'Select Country';

  @override
  String get useDifferentSim => 'Use a different SIM number';

  @override
  String get continueInfoBox =>
      'When you tap \"Continue\", we\'ll send you a text with a verification code.';

  @override
  String get enterVerificationCode => 'Enter verification\ncode';

  @override
  String codeSentToPhone(String phone) {
    return 'We sent a 6-digit code to $phone';
  }

  @override
  String get codeSentToPhoneFallback =>
      'We sent a 6-digit code to your phone number.';

  @override
  String get verificationSessionExpired =>
      'Verification session expired. Go back and try again.';

  @override
  String get invalidCode => 'Invalid code. Please try again.';

  @override
  String get verificationFailed => 'Verification failed. Please try again.';

  @override
  String get loginFailed => 'Login failed. Please try again.';

  @override
  String get couldNotCompleteLogin =>
      'Could not complete phone login. Please try again.';

  @override
  String get verifying => 'Verifying...';

  @override
  String get resendCode => 'Didn\'t receive it? Resend code';

  @override
  String get maxResendReached => 'Maximum resend attempts reached';

  @override
  String resendCodeIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String codeResent(int remaining) {
    return 'Code resent ($remaining left)';
  }

  @override
  String get smsRatesInfo =>
      'Standard SMS rates may apply. The code will expire in 10 minutes.';

  @override
  String get welcomeToDejTing => 'Welcome to DejTing.';

  @override
  String get followHouseRules => 'Please follow these House Rules.';

  @override
  String get ruleBeYourself => 'Be yourself';

  @override
  String get ruleBeYourselfDesc =>
      'Use authentic photos and accurate information about yourself.';

  @override
  String get ruleStaySafe => 'Stay safe';

  @override
  String get ruleStaySafeDesc =>
      'Protect your personal information and report any suspicious behavior.';

  @override
  String get rulePlayItCool => 'Play it cool';

  @override
  String get rulePlayItCoolDesc => 'Treat everyone with respect and kindness.';

  @override
  String get ruleBeProactive => 'Be proactive';

  @override
  String get ruleBeProactiveDesc =>
      'Take initiative and make meaningful connections.';

  @override
  String get iAgreeButton => 'I agree';

  @override
  String get whatsYourFirstName => 'What\'s your first name?';

  @override
  String get nameAppearOnProfile =>
      'This is how it\'ll appear on your profile.';

  @override
  String get firstNameHint => 'First name';

  @override
  String get yourBirthday => 'Your birthday?';

  @override
  String get birthdayExplainer =>
      'Your profile shows your age, not your date of birth.\nYou won\'t be able to change this later.';

  @override
  String get monthLabel => 'Month';

  @override
  String get dayLabel => 'Day';

  @override
  String get yearLabel => 'Year';

  @override
  String youAreNYearsOld(int age) {
    return 'You are $age years old';
  }

  @override
  String get ageRequirement => 'Age Requirement';

  @override
  String get mustBe18 => 'You must be 18 or older to use this app.';

  @override
  String get whatsYourGender => 'What\'s your\ngender?';

  @override
  String get genderMan => 'Man';

  @override
  String get genderWoman => 'Woman';

  @override
  String get genderNonBinary => 'Non-binary';

  @override
  String get genderOther => 'Other';

  @override
  String get moreOptions => 'More';

  @override
  String get selectGenderSheet => 'Select one that best\nrepresents you';

  @override
  String get showGenderOnProfile => 'Show my gender on my profile';

  @override
  String get whatsYourOrientation => 'What\'s your sexual\norientation?';

  @override
  String get selectOrientations =>
      'Select all that describe you to reflect your identity.';

  @override
  String get showOrientationOnProfile => 'Show my orientation on my profile';

  @override
  String get whatAreYouLookingFor => 'What are you\nlooking for?';

  @override
  String get notShownUnlessYouChoose =>
      'Not shown on profile unless you choose';

  @override
  String get showMe => 'Show me';

  @override
  String get prefMen => 'Men';

  @override
  String get prefWomen => 'Women';

  @override
  String get prefEveryone => 'Everyone';

  @override
  String get addPhotos => 'Add photos';

  @override
  String get photosSubtitle =>
      'Add at least 2 photos to continue. Your first photo is your profile photo.';

  @override
  String get takeAPhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get uploading => 'Uploading...';

  @override
  String photosReady(int count) {
    return '$count/6 photos · Ready!';
  }

  @override
  String addMorePhotos(int count, int remaining) {
    return '$count/6 photos · Add $remaining more';
  }

  @override
  String get tapToRetry => 'Tap to retry';

  @override
  String get mainPhotoBadge => 'Main';

  @override
  String get notAuthenticated => 'Not authenticated';

  @override
  String get photoUploadedSuccess => 'Photo uploaded successfully!';

  @override
  String get photoDeletedSuccess => 'Photo deleted successfully';

  @override
  String get primaryPhotoUpdated => 'Primary photo updated successfully';

  @override
  String get selectPhotoSource => 'Select Photo Source';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get deletePhotoTitle => 'Delete Photo';

  @override
  String get deletePhotoConfirmation =>
      'Are you sure you want to delete this photo?';

  @override
  String get primaryPhoto => 'Primary Photo';

  @override
  String photoNumber(int number) {
    return 'Photo $number';
  }

  @override
  String get requiredLabel => 'Required';

  @override
  String get primaryLabel => 'Primary';

  @override
  String get replacePhoto => 'Replace Photo';

  @override
  String get setAsPrimary => 'Set as Primary';

  @override
  String get deletePhoto => 'Delete Photo';

  @override
  String get photoTips => 'Photo Tips';

  @override
  String get photoTipsBody =>
      '• Use clear, high-quality photos\n• Make sure your face is visible\n• Avoid group photos as your primary\n• Show your personality and interests\n• Keep it recent and authentic';

  @override
  String get lifestyleHabits => 'Lifestyle habits';

  @override
  String get lifestyleSubtitle =>
      'These are optional but help find better matches and boost your profile completeness.';

  @override
  String get whatAreYouInto => 'What are you into?';

  @override
  String get whatMakesYouYou => 'What else makes\nyou, you?';

  @override
  String get authenticitySubtitle =>
      'Don\'t hold back. Authenticity attracts authenticity.';

  @override
  String get letsGo => 'Let\'s go! 🎉';

  @override
  String get skipAndFinish => 'Skip & finish';

  @override
  String get enableLocation => 'Enable location';

  @override
  String get locationDescription =>
      'We use your location to show you potential matches nearby. The closer they are, the easier it is to meet up!';

  @override
  String get enableLocationBtn => 'Enable Location';

  @override
  String get enableNotifications => 'Enable notifications';

  @override
  String get neverMissAMatch => 'Never miss a match';

  @override
  String get notificationDescription =>
      'Get notified when someone likes you, when you get a new match, or when you receive a message. Stay in the loop!';

  @override
  String get enableNotificationsBtn => 'Enable Notifications';

  @override
  String get settingUpProfile => 'Setting up your profile...';

  @override
  String get youreAllSet => 'You\'re all set!';

  @override
  String get profileReadySubtitle =>
      'Your profile is ready. Time to start\nmeeting amazing people.';

  @override
  String get startExploring => 'Start Exploring';

  @override
  String get discoverTitle => 'Discover';

  @override
  String get findingPeopleNearYou => 'Finding people near you...';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get checkConnectionRetry => 'Check your connection and try again';

  @override
  String get seenEveryone => 'You\'ve seen everyone!';

  @override
  String get checkBackLater => 'Check back later for new people';

  @override
  String get interestsHeader => 'INTERESTS';

  @override
  String get likeButton => 'Like';

  @override
  String get skipAction => 'Skip';

  @override
  String get addComment => 'Add a comment?';

  @override
  String get standOutComment => 'Stand out by telling them why you liked this';

  @override
  String get saySomethingNice => 'Say something nice...';

  @override
  String get likeOnly => 'Like only';

  @override
  String get sendWithComment => 'Send with comment';

  @override
  String get matchesTitle => 'Matches';

  @override
  String get newMatches => 'New Matches';

  @override
  String get messagesTab => 'Messages';

  @override
  String get noMatchesYet => 'No matches yet';

  @override
  String get keepSwiping => 'Keep swiping to find your perfect match!';

  @override
  String get unknownUser => 'Unknown';

  @override
  String get readyToChat => 'Ready to Chat';

  @override
  String get noConversationsYet => 'No conversations yet';

  @override
  String get startChattingMatches => 'Start chatting with your matches!';

  @override
  String get sayHello => 'Say hello!';

  @override
  String get replyAction => 'Reply';

  @override
  String get refreshMessages => 'Refresh messages';

  @override
  String get videoCallComingSoon => 'Video call coming soon!';

  @override
  String get safetyNotice =>
      'Your safety matters. This conversation is monitored for inappropriate content.';

  @override
  String get startConversation => 'Start your conversation!';

  @override
  String sayHelloTo(String name) {
    return 'Say hello to $name';
  }

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get failedToSendMessage => 'Failed to send message. Please try again.';

  @override
  String get reportUser => 'Report User';

  @override
  String get blockUser => 'Block User';

  @override
  String get safetyTips => 'Safety Tips';

  @override
  String get reportDialogContent =>
      'Report this user for inappropriate behavior. Our team will review your report.';

  @override
  String get userReported =>
      'User reported. Thank you for keeping our community safe.';

  @override
  String get blockDialogContent =>
      'This will prevent them from messaging you and hide their profile.';

  @override
  String get userBlocked => 'User blocked successfully.';

  @override
  String get staySafe => 'Stay Safe';

  @override
  String get safetyTip1 =>
      '• Never share personal information like your phone number, address, or financial details';

  @override
  String get safetyTip2 => '• Meet in public places for first dates';

  @override
  String get safetyTip3 =>
      '• Trust your instincts - if something feels wrong, report it';

  @override
  String get safetyTip4 =>
      '• Our AI monitors conversations for inappropriate content';

  @override
  String get safetyTip5 =>
      '• Report any suspicious or offensive behavior immediately';

  @override
  String get timeNow => 'now';

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusConnecting => 'Connecting...';

  @override
  String get statusReconnecting => 'Reconnecting...';

  @override
  String get aboutMeLabel => 'ABOUT ME';

  @override
  String get interestsLabel => 'INTERESTS';

  @override
  String get lifestyleLabel => 'LIFESTYLE';

  @override
  String get languagesLabel => 'LANGUAGES';

  @override
  String percentCompatible(int percent) {
    return '$percent% Compatible';
  }

  @override
  String get basedOnPreferences => 'based on your preferences';

  @override
  String get drinkingLabel => 'Drinking';

  @override
  String get smokingLabel => 'Smoking';

  @override
  String get workoutLabel => 'Workout';

  @override
  String kmAway(int km) {
    return '$km km away';
  }

  @override
  String get sendAMessage => 'Send a Message';

  @override
  String get reportProfile => 'Report Profile';

  @override
  String get reportSubmitted => 'Report submitted. Thank you.';

  @override
  String userHasBeenBlocked(String name) {
    return '$name has been blocked.';
  }

  @override
  String get getMore => 'Get more';

  @override
  String get safety => 'Safety';

  @override
  String get myDejTing => 'My DejTing';

  @override
  String get dejTingPlus => 'DejTing Plus';

  @override
  String get dejTingPlusSubtitle =>
      'Unlimited Sparks, weekly Spotlight,\nand see who likes you first.';

  @override
  String get spotlight => 'Spotlight';

  @override
  String get spotlightSubtitle =>
      'Jump to the front — get seen by 10× more people for 30 min.';

  @override
  String get sparks => 'Sparks';

  @override
  String get sparkSubtitle =>
      'Send a Spark with a message — 3× more likely to match.';

  @override
  String get profileStrength => 'Profile Strength';

  @override
  String get selfieVerification => 'Selfie verification';

  @override
  String get youAreVerified => 'You\'re verified ✓';

  @override
  String get verifyYourIdentity => 'Verify your identity';

  @override
  String get messageFilter => 'Message filter';

  @override
  String get messageFilterSubtitle =>
      'Hiding messages with disrespectful language.';

  @override
  String get blockList => 'Block list';

  @override
  String contactsBlocked(int count) {
    return '$count contact(s) blocked.';
  }

  @override
  String get safetyResources => 'Safety resources';

  @override
  String get crisisHotlines => 'Crisis hotlines';

  @override
  String get freshStart => 'Fresh start';

  @override
  String get freshStartSubtitle =>
      'Update your prompts and photos\nto spark new conversations.';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get datingTips => 'Dating tips';

  @override
  String get datingTipsSubtitle => 'Expert-backed advice for better dates';

  @override
  String get helpCentre => 'Help centre';

  @override
  String get helpCentreSubtitle => 'FAQs, safety and account support';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Discovery, notifications, privacy';

  @override
  String get noBlockedContacts => 'No blocked contacts';

  @override
  String featureComingSoon(String feature) {
    return '$feature — coming soon!';
  }

  @override
  String get sectionAccount => 'Account';

  @override
  String get editProfileSubtitle => 'Update your photos and bio';

  @override
  String get verifyAccount => 'Verify Your Account';

  @override
  String get verifyAccountSubtitle => 'Get a blue checkmark';

  @override
  String get privacySecurity => 'Privacy & Security';

  @override
  String get privacySecuritySubtitle => 'Control your privacy settings';

  @override
  String get sectionDiscovery => 'Discovery Settings';

  @override
  String get locationLabel => 'Location';

  @override
  String get locationSubtitle => 'Update your location';

  @override
  String maxDistance(int km) {
    return 'Maximum Distance: $km km';
  }

  @override
  String ageRangeLabel(int min, int max) {
    return 'Age Range: $min - $max';
  }

  @override
  String get showMeOnDejTing => 'Show me on DejTing';

  @override
  String get pauseAccountSubtitle => 'Turn off to pause your account';

  @override
  String get sectionNotifications => 'Notifications';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get pushNotificationsSubtitle => 'New matches and messages';

  @override
  String get sectionProfileDisplay => 'Profile Display';

  @override
  String get showAge => 'Show Age';

  @override
  String get showAgeSubtitle => 'Display your age on your profile';

  @override
  String get showDistance => 'Show Distance';

  @override
  String get showDistanceSubtitle => 'Display distance on your profile';

  @override
  String get sectionSupportAbout => 'Support & About';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get aboutLabel => 'About';

  @override
  String get rateUs => 'Rate Us';

  @override
  String get aboutAppTitle => 'About DatingApp';

  @override
  String get versionNumber => 'Version: 1.0.0';

  @override
  String get aboutAppDescription =>
      'Find your perfect match with our AI-powered dating app.';

  @override
  String get madeByTeam => 'Made with ❤️ by the DatingApp Team';

  @override
  String get verifyIdentityTitle => 'Verify Your Identity';

  @override
  String get takeSelfieToVerify => 'Take a Selfie to Verify';

  @override
  String get selfieVerifyDescription =>
      'We compare your selfie to your profile photo to confirm it\'s really you. This keeps everyone safe.';

  @override
  String get selfieTip1 => 'Good lighting, face clearly visible';

  @override
  String get selfieTip2 => 'Look straight at camera';

  @override
  String get selfieTip3 => 'No sunglasses, masks, or heavy filters';

  @override
  String attemptsRemainingToday(int count) {
    return '$count attempt(s) remaining today';
  }

  @override
  String get takeSelfie => 'Take Selfie';

  @override
  String get lookingGood => 'Looking good?';

  @override
  String get selfiePreviewDescription =>
      'Make sure your face is clearly visible and matches your profile photo.';

  @override
  String get verifyingIdentity => 'Verifying your identity...';

  @override
  String get submitForVerification => 'Submit for Verification';

  @override
  String get retakePhoto => 'Retake Photo';

  @override
  String get verified => 'Verified!';

  @override
  String get underReview => 'Under Review';

  @override
  String get verificationFailedResult => 'Verification Failed';

  @override
  String get alreadyVerified => 'You\'re Already Verified!';

  @override
  String get alreadyVerifiedDescription =>
      'Your identity has been confirmed. Other users can see your blue verification badge.';

  @override
  String get verifiedProfile => 'Verified profile';

  @override
  String get getVerified => 'Get Verified';

  @override
  String get profileComplete => 'Profile complete! 🎉';

  @override
  String get profileAlmostThere => 'Almost there — add a few more details';

  @override
  String get profileLookingGood => 'Looking good — keep going!';

  @override
  String get addMoreInfoForMatches => 'Add more info to get matches';

  @override
  String get completeLabel => 'complete';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get failedToLoad => 'Failed to load';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetworkUnavailable =>
      'Network unavailable. Please check your connection.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please log in again.';

  @override
  String get errorFieldRequired => 'This field is required';

  @override
  String errorLoadingMessages(String error) {
    return 'Failed to load messages: $error';
  }

  @override
  String errorSendingMessage(String error) {
    return 'Error sending message: $error';
  }

  @override
  String get profileTab => 'Profile';

  @override
  String get settingsTab => 'Settings';

  @override
  String get noNewPeople => 'Check back later for new people';

  @override
  String get connectionError => 'Check your connection and try again';

  @override
  String get connected => 'Connected';

  @override
  String get connecting => 'Connecting...';

  @override
  String get aboutApp => 'About DatingApp';

  @override
  String get accountSection => 'Account';

  @override
  String get privacySettings => 'Control your privacy settings';

  @override
  String get onboardingPhoneHint => 'Enter your phone number';

  @override
  String get onboardingVerifyCode => 'Verify Code';

  @override
  String get onboardingVerifying => 'Verifying...';

  @override
  String onboardingCodeResent(int remaining) {
    return 'Code resent ($remaining left)';
  }

  @override
  String get onboardingSelectCountry => 'Select Country';

  @override
  String get onboardingFirstNameTitle => 'What\'s your first name?';

  @override
  String get onboardingBirthdayTitle => 'When\'s your birthday?';

  @override
  String get onboardingGenderTitle => 'What\'s your gender?';

  @override
  String get onboardingOrientationTitle => 'What\'s your orientation?';

  @override
  String get onboardingRelationshipGoalsTitle => 'What are you looking for?';

  @override
  String get onboardingMatchPrefsTitle => 'Match Preferences';

  @override
  String get onboardingPhotosTitle => 'Add Photos';

  @override
  String get onboardingLifestyleTitle => 'Lifestyle';

  @override
  String get onboardingInterestsTitle => 'Interests';

  @override
  String get onboardingAboutMeTitle => 'About me';

  @override
  String get onboardingLocationTitle => 'Enable Location';

  @override
  String get onboardingLocationSubtitle =>
      'We use your location to show you potential matches nearby';

  @override
  String get enableLocationButton => 'Enable Location';

  @override
  String get maybeLaterButton => 'Maybe Later';

  @override
  String get onboardingNotificationsTitle => 'Enable Notifications';

  @override
  String get onboardingNotificationsSubtitle =>
      'Get notified when someone likes you or sends a message';

  @override
  String get enableNotificationsButton => 'Enable Notifications';

  @override
  String get onboardingCompleteTitle => 'You\'re All Set!';

  @override
  String get onboardingCompleteSubtitle =>
      'Your profile is ready. Start discovering amazing people!';

  @override
  String get startDiscoveringButton => 'Start Discovering';

  @override
  String photoAdded(int index) {
    return 'Photo $index added (placeholder)';
  }

  @override
  String addUpToInterests(int max) {
    return 'Add up to $max interests to show on your profile.';
  }

  @override
  String get verificationSubtitle => 'Get a blue checkmark';

  @override
  String get notificationsSubtitle => 'New matches and messages';

  @override
  String get getMoreSparks => 'Get more Sparks';

  @override
  String get matchFound => 'It\'s a match!';

  @override
  String get continueBtn => 'Continue';

  @override
  String get voicePromptTitle => 'Voice Prompt';

  @override
  String get voicePromptInstruction =>
      'Record a short voice intro so matches can hear your vibe';

  @override
  String get voicePromptRecording => 'Recording… tap stop when you\'re done';

  @override
  String get voicePromptReview =>
      'Listen to your recording and choose to save or re-record';
}
