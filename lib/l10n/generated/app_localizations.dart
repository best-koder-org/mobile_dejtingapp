import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sv.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sv')
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'DejTing'**
  String get appTitle;

  /// Brand name
  ///
  /// In en, this message translates to:
  /// **'DejTing'**
  String get appName;

  /// Continue button label
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Next button label
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// Done button label
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// Skip button label
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipButton;

  /// Back button label
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// OK button label
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButton;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// Report button label
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportButton;

  /// Block button label
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockButton;

  /// Got it button label
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotItButton;

  /// Close button label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// Go back button label
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBackButton;

  /// Try again button label
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgainButton;

  /// Refresh button label
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshButton;

  /// Upgrade button label
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradeButton;

  /// Manage button label
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manageButton;

  /// Unblock button label
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockButton;

  /// Logout button label
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButton;

  /// Skip for now button label
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// Not now button label
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// Coming soon label
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// Divider text between options
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// Bottom nav discover tab
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// Bottom nav matches tab
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get navMatches;

  /// Bottom nav profile tab
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Login screen title
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginTitle;

  /// Registration screen title
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// Login screen tagline
  ///
  /// In en, this message translates to:
  /// **'Find your perfect match'**
  String get loginTagline;

  /// Auth info heading
  ///
  /// In en, this message translates to:
  /// **'No passwords needed'**
  String get noPasswordsNeeded;

  /// Phone sign in description
  ///
  /// In en, this message translates to:
  /// **'Sign in with your phone number.\nWe\'ll text you a verification code.'**
  String get phoneSignInDescription;

  /// Phone sign in button
  ///
  /// In en, this message translates to:
  /// **'Continue with Phone Number'**
  String get continueWithPhone;

  /// Apple sign-in button
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// Google sign-in button
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Browser sign in fallback
  ///
  /// In en, this message translates to:
  /// **'Sign in with Browser'**
  String get signInWithBrowser;

  /// Phone sign in link
  ///
  /// In en, this message translates to:
  /// **'Sign in with phone number'**
  String get signInWithPhone;

  /// Browser login error
  ///
  /// In en, this message translates to:
  /// **'Browser login failed. Please try again.'**
  String get browserLoginFailed;

  /// Back to login link
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// Trouble logging in link
  ///
  /// In en, this message translates to:
  /// **'Trouble Logging In?'**
  String get troubleLoggingIn;

  /// Logout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// Auth required message
  ///
  /// In en, this message translates to:
  /// **'Authentication required'**
  String get authRequired;

  /// Auth required detail message
  ///
  /// In en, this message translates to:
  /// **'Authentication required. Please log in again.'**
  String get authRequiredDetail;

  /// Create account heading
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// Terms intro text
  ///
  /// In en, this message translates to:
  /// **'By tapping Log In or Continue, you agree to our '**
  String get termsIntro;

  /// Terms link text
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get termsLink;

  /// Privacy intro text
  ///
  /// In en, this message translates to:
  /// **'. Learn how we process your data in our '**
  String get privacyIntro;

  /// Privacy Policy link text
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyLink;

  /// Phone entry screen title
  ///
  /// In en, this message translates to:
  /// **'Can we get your number?'**
  String get onboardingPhoneTitle;

  /// Phone verification explainer
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a text with a verification code. Message and data rates may apply.'**
  String get phoneVerificationExplainer;

  /// Phone number input hint
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberHint;

  /// Mobile-only error
  ///
  /// In en, this message translates to:
  /// **'Phone verification requires a mobile device (Android/iOS).'**
  String get phoneVerificationMobileOnly;

  /// Failed to send code error
  ///
  /// In en, this message translates to:
  /// **'Failed to send verification code. Please try again.'**
  String get failedToSendCode;

  /// Country selector title
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get selectCountry;

  /// Different SIM link
  ///
  /// In en, this message translates to:
  /// **'Use a different SIM number'**
  String get useDifferentSim;

  /// Continue info box
  ///
  /// In en, this message translates to:
  /// **'When you tap \"Continue\", we\'ll send you a text with a verification code.'**
  String get continueInfoBox;

  /// SMS code screen title
  ///
  /// In en, this message translates to:
  /// **'Enter verification\ncode'**
  String get enterVerificationCode;

  /// Code sent message
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {phone}'**
  String codeSentToPhone(String phone);

  /// Code sent fallback
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to your phone number.'**
  String get codeSentToPhoneFallback;

  /// Session expired error
  ///
  /// In en, this message translates to:
  /// **'Verification session expired. Go back and try again.'**
  String get verificationSessionExpired;

  /// Invalid code error
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Please try again.'**
  String get invalidCode;

  /// Verification failed error
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please try again.'**
  String get verificationFailed;

  /// Login failed error
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginFailed;

  /// Could not complete login
  ///
  /// In en, this message translates to:
  /// **'Could not complete phone login. Please try again.'**
  String get couldNotCompleteLogin;

  /// Verifying loading text
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get verifying;

  /// Resend code link
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive it? Resend code'**
  String get resendCode;

  /// Max resend reached
  ///
  /// In en, this message translates to:
  /// **'Maximum resend attempts reached'**
  String get maxResendReached;

  /// Resend timer
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeIn(int seconds);

  /// Code resent message
  ///
  /// In en, this message translates to:
  /// **'Code resent ({remaining} left)'**
  String codeResent(int remaining);

  /// SMS rates info
  ///
  /// In en, this message translates to:
  /// **'Standard SMS rates may apply. The code will expire in 10 minutes.'**
  String get smsRatesInfo;

  /// Community guidelines title
  ///
  /// In en, this message translates to:
  /// **'Welcome to DejTing.'**
  String get welcomeToDejTing;

  /// Community guidelines subtitle
  ///
  /// In en, this message translates to:
  /// **'Please follow these House Rules.'**
  String get followHouseRules;

  /// Rule 1 title
  ///
  /// In en, this message translates to:
  /// **'Be yourself'**
  String get ruleBeYourself;

  /// Rule 1 description
  ///
  /// In en, this message translates to:
  /// **'Use authentic photos and accurate information about yourself.'**
  String get ruleBeYourselfDesc;

  /// Rule 2 title
  ///
  /// In en, this message translates to:
  /// **'Stay safe'**
  String get ruleStaySafe;

  /// Rule 2 description
  ///
  /// In en, this message translates to:
  /// **'Protect your personal information and report any suspicious behavior.'**
  String get ruleStaySafeDesc;

  /// Rule 3 title
  ///
  /// In en, this message translates to:
  /// **'Play it cool'**
  String get rulePlayItCool;

  /// Rule 3 description
  ///
  /// In en, this message translates to:
  /// **'Treat everyone with respect and kindness.'**
  String get rulePlayItCoolDesc;

  /// Rule 4 title
  ///
  /// In en, this message translates to:
  /// **'Be proactive'**
  String get ruleBeProactive;

  /// Rule 4 description
  ///
  /// In en, this message translates to:
  /// **'Take initiative and make meaningful connections.'**
  String get ruleBeProactiveDesc;

  /// Agree button
  ///
  /// In en, this message translates to:
  /// **'I agree'**
  String get iAgreeButton;

  /// First name screen title
  ///
  /// In en, this message translates to:
  /// **'What\'s your first name?'**
  String get whatsYourFirstName;

  /// First name subtitle
  ///
  /// In en, this message translates to:
  /// **'This is how it\'ll appear on your profile.'**
  String get nameAppearOnProfile;

  /// First name input hint
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstNameHint;

  /// Birthday screen title
  ///
  /// In en, this message translates to:
  /// **'Your birthday?'**
  String get yourBirthday;

  /// Birthday explainer
  ///
  /// In en, this message translates to:
  /// **'Your profile shows your age, not your date of birth.\nYou won\'t be able to change this later.'**
  String get birthdayExplainer;

  /// Month dropdown label
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthLabel;

  /// Day dropdown label
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dayLabel;

  /// Year dropdown label
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get yearLabel;

  /// Age display
  ///
  /// In en, this message translates to:
  /// **'You are {age} years old'**
  String youAreNYearsOld(int age);

  /// Age requirement dialog title
  ///
  /// In en, this message translates to:
  /// **'Age Requirement'**
  String get ageRequirement;

  /// Must be 18+ message
  ///
  /// In en, this message translates to:
  /// **'You must be 18 or older to use this app.'**
  String get mustBe18;

  /// Gender screen title
  ///
  /// In en, this message translates to:
  /// **'What\'s your\ngender?'**
  String get whatsYourGender;

  /// Gender: Man
  ///
  /// In en, this message translates to:
  /// **'Man'**
  String get genderMan;

  /// Gender: Woman
  ///
  /// In en, this message translates to:
  /// **'Woman'**
  String get genderWoman;

  /// Gender: Non-binary
  ///
  /// In en, this message translates to:
  /// **'Non-binary'**
  String get genderNonBinary;

  /// Gender: Other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// More options button
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreOptions;

  /// Gender sheet title
  ///
  /// In en, this message translates to:
  /// **'Select one that best\nrepresents you'**
  String get selectGenderSheet;

  /// Show gender checkbox
  ///
  /// In en, this message translates to:
  /// **'Show my gender on my profile'**
  String get showGenderOnProfile;

  /// Orientation screen title
  ///
  /// In en, this message translates to:
  /// **'What\'s your sexual\norientation?'**
  String get whatsYourOrientation;

  /// Orientation subtitle
  ///
  /// In en, this message translates to:
  /// **'Select all that describe you to reflect your identity.'**
  String get selectOrientations;

  /// Show orientation checkbox
  ///
  /// In en, this message translates to:
  /// **'Show my orientation on my profile'**
  String get showOrientationOnProfile;

  /// Relationship goals title
  ///
  /// In en, this message translates to:
  /// **'What are you\nlooking for?'**
  String get whatAreYouLookingFor;

  /// Goals disclaimer
  ///
  /// In en, this message translates to:
  /// **'Not shown on profile unless you choose'**
  String get notShownUnlessYouChoose;

  /// Match preferences title
  ///
  /// In en, this message translates to:
  /// **'Show me'**
  String get showMe;

  /// Preference: Men
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get prefMen;

  /// Preference: Women
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get prefWomen;

  /// Preference: Everyone
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get prefEveryone;

  /// Photos screen title
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get addPhotos;

  /// Photos subtitle
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 photos to continue. Your first photo is your profile photo.'**
  String get photosSubtitle;

  /// Camera option
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takeAPhoto;

  /// Gallery option
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// Upload progress text
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// Photos ready status
  ///
  /// In en, this message translates to:
  /// **'{count}/6 photos · Ready!'**
  String photosReady(int count);

  /// Add more photos status
  ///
  /// In en, this message translates to:
  /// **'{count}/6 photos · Add {remaining} more'**
  String addMorePhotos(int count, int remaining);

  /// Retry hint
  ///
  /// In en, this message translates to:
  /// **'Tap to retry'**
  String get tapToRetry;

  /// Main photo badge
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get mainPhotoBadge;

  /// Not authenticated error
  ///
  /// In en, this message translates to:
  /// **'Not authenticated'**
  String get notAuthenticated;

  /// Photo upload success
  ///
  /// In en, this message translates to:
  /// **'Photo uploaded successfully!'**
  String get photoUploadedSuccess;

  /// Photo deleted success
  ///
  /// In en, this message translates to:
  /// **'Photo deleted successfully'**
  String get photoDeletedSuccess;

  /// Primary photo updated
  ///
  /// In en, this message translates to:
  /// **'Primary photo updated successfully'**
  String get primaryPhotoUpdated;

  /// Photo source dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Photo Source'**
  String get selectPhotoSource;

  /// Camera option
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// Gallery option
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// Delete photo dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Photo'**
  String get deletePhotoTitle;

  /// Delete photo confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this photo?'**
  String get deletePhotoConfirmation;

  /// Primary photo slot label
  ///
  /// In en, this message translates to:
  /// **'Primary Photo'**
  String get primaryPhoto;

  /// Photo slot label
  ///
  /// In en, this message translates to:
  /// **'Photo {number}'**
  String photoNumber(int number);

  /// Required label
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredLabel;

  /// Primary badge
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get primaryLabel;

  /// Replace photo option
  ///
  /// In en, this message translates to:
  /// **'Replace Photo'**
  String get replacePhoto;

  /// Set as primary option
  ///
  /// In en, this message translates to:
  /// **'Set as Primary'**
  String get setAsPrimary;

  /// Delete photo option
  ///
  /// In en, this message translates to:
  /// **'Delete Photo'**
  String get deletePhoto;

  /// Photo tips heading
  ///
  /// In en, this message translates to:
  /// **'Photo Tips'**
  String get photoTips;

  /// Photo tips body
  ///
  /// In en, this message translates to:
  /// **'• Use clear, high-quality photos\n• Make sure your face is visible\n• Avoid group photos as your primary\n• Show your personality and interests\n• Keep it recent and authentic'**
  String get photoTipsBody;

  /// Lifestyle screen title
  ///
  /// In en, this message translates to:
  /// **'Lifestyle habits'**
  String get lifestyleHabits;

  /// Lifestyle subtitle
  ///
  /// In en, this message translates to:
  /// **'These are optional but help find better matches and boost your profile completeness.'**
  String get lifestyleSubtitle;

  /// Interests screen title
  ///
  /// In en, this message translates to:
  /// **'What are you into?'**
  String get whatAreYouInto;

  /// About me screen title
  ///
  /// In en, this message translates to:
  /// **'What else makes\nyou, you?'**
  String get whatMakesYouYou;

  /// About me subtitle
  ///
  /// In en, this message translates to:
  /// **'Don\'t hold back. Authenticity attracts authenticity.'**
  String get authenticitySubtitle;

  /// Finish onboarding button
  ///
  /// In en, this message translates to:
  /// **'Let\'s go! 🎉'**
  String get letsGo;

  /// Skip and finish button
  ///
  /// In en, this message translates to:
  /// **'Skip & finish'**
  String get skipAndFinish;

  /// Location screen title
  ///
  /// In en, this message translates to:
  /// **'Enable location'**
  String get enableLocation;

  /// Location description
  ///
  /// In en, this message translates to:
  /// **'We use your location to show you potential matches nearby. The closer they are, the easier it is to meet up!'**
  String get locationDescription;

  /// Enable location button
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get enableLocationBtn;

  /// Notifications screen title
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get enableNotifications;

  /// Notifications accent subtitle
  ///
  /// In en, this message translates to:
  /// **'Never miss a match'**
  String get neverMissAMatch;

  /// Notifications description
  ///
  /// In en, this message translates to:
  /// **'Get notified when someone likes you, when you get a new match, or when you receive a message. Stay in the loop!'**
  String get notificationDescription;

  /// Enable notifications button
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotificationsBtn;

  /// Profile setup loading
  ///
  /// In en, this message translates to:
  /// **'Setting up your profile...'**
  String get settingUpProfile;

  /// Onboarding complete title
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get youreAllSet;

  /// Profile ready subtitle
  ///
  /// In en, this message translates to:
  /// **'Your profile is ready. Time to start\nmeeting amazing people.'**
  String get profileReadySubtitle;

  /// Start exploring button
  ///
  /// In en, this message translates to:
  /// **'Start Exploring'**
  String get startExploring;

  /// Discover screen title
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// Discovery loading text
  ///
  /// In en, this message translates to:
  /// **'Finding people near you...'**
  String get findingPeopleNearYou;

  /// Generic error title
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// Connection error subtitle
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again'**
  String get checkConnectionRetry;

  /// No more profiles title
  ///
  /// In en, this message translates to:
  /// **'You\'ve seen everyone!'**
  String get seenEveryone;

  /// No more profiles subtitle
  ///
  /// In en, this message translates to:
  /// **'Check back later for new people'**
  String get checkBackLater;

  /// Interests section header
  ///
  /// In en, this message translates to:
  /// **'INTERESTS'**
  String get interestsHeader;

  /// Like button label
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get likeButton;

  /// Skip action label
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipAction;

  /// Add comment placeholder
  ///
  /// In en, this message translates to:
  /// **'Add a comment?'**
  String get addComment;

  /// Like sheet subtitle
  ///
  /// In en, this message translates to:
  /// **'Stand out by telling them why you liked this'**
  String get standOutComment;

  /// Comment hint text
  ///
  /// In en, this message translates to:
  /// **'Say something nice...'**
  String get saySomethingNice;

  /// Like without comment button
  ///
  /// In en, this message translates to:
  /// **'Like only'**
  String get likeOnly;

  /// Send like with comment
  ///
  /// In en, this message translates to:
  /// **'Send with comment'**
  String get sendWithComment;

  /// Matches screen title
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matchesTitle;

  /// New matches section
  ///
  /// In en, this message translates to:
  /// **'New Matches'**
  String get newMatches;

  /// Messages tab label
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTab;

  /// Empty matches title
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get noMatchesYet;

  /// Empty matches subtitle
  ///
  /// In en, this message translates to:
  /// **'Keep swiping to find your perfect match!'**
  String get keepSwiping;

  /// Fallback display name
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownUser;

  /// Ready to chat section
  ///
  /// In en, this message translates to:
  /// **'Ready to Chat'**
  String get readyToChat;

  /// Empty messages title
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// Empty messages subtitle
  ///
  /// In en, this message translates to:
  /// **'Start chatting with your matches!'**
  String get startChattingMatches;

  /// Fallback match subtitle
  ///
  /// In en, this message translates to:
  /// **'Say hello!'**
  String get sayHello;

  /// Reply snackbar action
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get replyAction;

  /// Refresh messages tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh messages'**
  String get refreshMessages;

  /// Video call coming soon
  ///
  /// In en, this message translates to:
  /// **'Video call coming soon!'**
  String get videoCallComingSoon;

  /// Chat safety notice
  ///
  /// In en, this message translates to:
  /// **'Your safety matters. This conversation is monitored for inappropriate content.'**
  String get safetyNotice;

  /// Empty chat title
  ///
  /// In en, this message translates to:
  /// **'Start your conversation!'**
  String get startConversation;

  /// Empty chat subtitle
  ///
  /// In en, this message translates to:
  /// **'Say hello to {name}'**
  String sayHelloTo(String name);

  /// Message input hint
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// Send message error
  ///
  /// In en, this message translates to:
  /// **'Failed to send message. Please try again.'**
  String get failedToSendMessage;

  /// Report user action
  ///
  /// In en, this message translates to:
  /// **'Report User'**
  String get reportUser;

  /// Block user action
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUser;

  /// Safety tips option
  ///
  /// In en, this message translates to:
  /// **'Safety Tips'**
  String get safetyTips;

  /// Report dialog content
  ///
  /// In en, this message translates to:
  /// **'Report this user for inappropriate behavior. Our team will review your report.'**
  String get reportDialogContent;

  /// User reported confirmation
  ///
  /// In en, this message translates to:
  /// **'User reported. Thank you for keeping our community safe.'**
  String get userReported;

  /// Block dialog content
  ///
  /// In en, this message translates to:
  /// **'This will prevent them from messaging you and hide their profile.'**
  String get blockDialogContent;

  /// User blocked confirmation
  ///
  /// In en, this message translates to:
  /// **'User blocked successfully.'**
  String get userBlocked;

  /// Safety dialog title
  ///
  /// In en, this message translates to:
  /// **'Stay Safe'**
  String get staySafe;

  /// Safety tip 1
  ///
  /// In en, this message translates to:
  /// **'• Never share personal information like your phone number, address, or financial details'**
  String get safetyTip1;

  /// Safety tip 2
  ///
  /// In en, this message translates to:
  /// **'• Meet in public places for first dates'**
  String get safetyTip2;

  /// Safety tip 3
  ///
  /// In en, this message translates to:
  /// **'• Trust your instincts - if something feels wrong, report it'**
  String get safetyTip3;

  /// Safety tip 4
  ///
  /// In en, this message translates to:
  /// **'• Our AI monitors conversations for inappropriate content'**
  String get safetyTip4;

  /// Safety tip 5
  ///
  /// In en, this message translates to:
  /// **'• Report any suspicious or offensive behavior immediately'**
  String get safetyTip5;

  /// Time: now
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get timeNow;

  /// Connection status: Connected
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get statusConnected;

  /// Connection status: Connecting
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get statusConnecting;

  /// Connection status: Reconnecting
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get statusReconnecting;

  /// About me section
  ///
  /// In en, this message translates to:
  /// **'ABOUT ME'**
  String get aboutMeLabel;

  /// Interests section
  ///
  /// In en, this message translates to:
  /// **'INTERESTS'**
  String get interestsLabel;

  /// Lifestyle section
  ///
  /// In en, this message translates to:
  /// **'LIFESTYLE'**
  String get lifestyleLabel;

  /// Languages section
  ///
  /// In en, this message translates to:
  /// **'LANGUAGES'**
  String get languagesLabel;

  /// Compatibility badge
  ///
  /// In en, this message translates to:
  /// **'{percent}% Compatible'**
  String percentCompatible(int percent);

  /// Compatibility subtitle
  ///
  /// In en, this message translates to:
  /// **'based on your preferences'**
  String get basedOnPreferences;

  /// Drinking lifestyle label
  ///
  /// In en, this message translates to:
  /// **'Drinking'**
  String get drinkingLabel;

  /// Smoking lifestyle label
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get smokingLabel;

  /// Workout lifestyle label
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workoutLabel;

  /// Distance text
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String kmAway(int km);

  /// Send message button
  ///
  /// In en, this message translates to:
  /// **'Send a Message'**
  String get sendAMessage;

  /// Report profile option
  ///
  /// In en, this message translates to:
  /// **'Report Profile'**
  String get reportProfile;

  /// Report submitted confirmation
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you.'**
  String get reportSubmitted;

  /// User blocked message
  ///
  /// In en, this message translates to:
  /// **'{name} has been blocked.'**
  String userHasBeenBlocked(String name);

  /// Get more tab
  ///
  /// In en, this message translates to:
  /// **'Get more'**
  String get getMore;

  /// Safety tab
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get safety;

  /// My DejTing tab
  ///
  /// In en, this message translates to:
  /// **'My DejTing'**
  String get myDejTing;

  /// Plus subscription title
  ///
  /// In en, this message translates to:
  /// **'DejTing Plus'**
  String get dejTingPlus;

  /// Plus subtitle
  ///
  /// In en, this message translates to:
  /// **'Unlimited Sparks, weekly Spotlight,\nand see who likes you first.'**
  String get dejTingPlusSubtitle;

  /// Spotlight feature
  ///
  /// In en, this message translates to:
  /// **'Spotlight'**
  String get spotlight;

  /// Spotlight subtitle
  ///
  /// In en, this message translates to:
  /// **'Jump to the front — get seen by 10× more people for 30 min.'**
  String get spotlightSubtitle;

  /// Sparks feature
  ///
  /// In en, this message translates to:
  /// **'Sparks'**
  String get sparks;

  /// Spark subtitle
  ///
  /// In en, this message translates to:
  /// **'Send a Spark with a message — 3× more likely to match.'**
  String get sparkSubtitle;

  /// Profile strength feature
  ///
  /// In en, this message translates to:
  /// **'Profile Strength'**
  String get profileStrength;

  /// Selfie verification title
  ///
  /// In en, this message translates to:
  /// **'Selfie verification'**
  String get selfieVerification;

  /// Verified subtitle
  ///
  /// In en, this message translates to:
  /// **'You\'re verified ✓'**
  String get youAreVerified;

  /// Unverified subtitle
  ///
  /// In en, this message translates to:
  /// **'Verify your identity'**
  String get verifyYourIdentity;

  /// Message filter title
  ///
  /// In en, this message translates to:
  /// **'Message filter'**
  String get messageFilter;

  /// Message filter subtitle
  ///
  /// In en, this message translates to:
  /// **'Hiding messages with disrespectful language.'**
  String get messageFilterSubtitle;

  /// Block list title
  ///
  /// In en, this message translates to:
  /// **'Block list'**
  String get blockList;

  /// Blocked count
  ///
  /// In en, this message translates to:
  /// **'{count} contact(s) blocked.'**
  String contactsBlocked(int count);

  /// Safety resources heading
  ///
  /// In en, this message translates to:
  /// **'Safety resources'**
  String get safetyResources;

  /// Crisis hotlines button
  ///
  /// In en, this message translates to:
  /// **'Crisis hotlines'**
  String get crisisHotlines;

  /// Fresh start card
  ///
  /// In en, this message translates to:
  /// **'Fresh start'**
  String get freshStart;

  /// Fresh start subtitle
  ///
  /// In en, this message translates to:
  /// **'Update your prompts and photos\nto spark new conversations.'**
  String get freshStartSubtitle;

  /// Edit profile button
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// Dating tips title
  ///
  /// In en, this message translates to:
  /// **'Dating tips'**
  String get datingTips;

  /// Dating tips subtitle
  ///
  /// In en, this message translates to:
  /// **'Expert-backed advice for better dates'**
  String get datingTipsSubtitle;

  /// Help centre title
  ///
  /// In en, this message translates to:
  /// **'Help centre'**
  String get helpCentre;

  /// Help centre subtitle
  ///
  /// In en, this message translates to:
  /// **'FAQs, safety and account support'**
  String get helpCentreSubtitle;

  /// Settings title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Discovery, notifications, privacy'**
  String get settingsSubtitle;

  /// Empty block list
  ///
  /// In en, this message translates to:
  /// **'No blocked contacts'**
  String get noBlockedContacts;

  /// Feature coming soon
  ///
  /// In en, this message translates to:
  /// **'{feature} — coming soon!'**
  String featureComingSoon(String feature);

  /// Account section header
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get sectionAccount;

  /// Edit profile subtitle
  ///
  /// In en, this message translates to:
  /// **'Update your photos and bio'**
  String get editProfileSubtitle;

  /// Verify account title
  ///
  /// In en, this message translates to:
  /// **'Verify Your Account'**
  String get verifyAccount;

  /// Verify account subtitle
  ///
  /// In en, this message translates to:
  /// **'Get a blue checkmark'**
  String get verifyAccountSubtitle;

  /// Privacy & Security title
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurity;

  /// Privacy subtitle
  ///
  /// In en, this message translates to:
  /// **'Control your privacy settings'**
  String get privacySecuritySubtitle;

  /// Discovery section header
  ///
  /// In en, this message translates to:
  /// **'Discovery Settings'**
  String get sectionDiscovery;

  /// Location setting title
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// Location setting subtitle
  ///
  /// In en, this message translates to:
  /// **'Update your location'**
  String get locationSubtitle;

  /// Max distance label
  ///
  /// In en, this message translates to:
  /// **'Maximum Distance: {km} km'**
  String maxDistance(int km);

  /// Age range label
  ///
  /// In en, this message translates to:
  /// **'Age Range: {min} - {max}'**
  String ageRangeLabel(int min, int max);

  /// Show me toggle
  ///
  /// In en, this message translates to:
  /// **'Show me on DejTing'**
  String get showMeOnDejTing;

  /// Pause account subtitle
  ///
  /// In en, this message translates to:
  /// **'Turn off to pause your account'**
  String get pauseAccountSubtitle;

  /// Notifications section
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get sectionNotifications;

  /// Push notifications toggle
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// Push notifications subtitle
  ///
  /// In en, this message translates to:
  /// **'New matches and messages'**
  String get pushNotificationsSubtitle;

  /// Profile display section
  ///
  /// In en, this message translates to:
  /// **'Profile Display'**
  String get sectionProfileDisplay;

  /// Show age toggle
  ///
  /// In en, this message translates to:
  /// **'Show Age'**
  String get showAge;

  /// Show age subtitle
  ///
  /// In en, this message translates to:
  /// **'Display your age on your profile'**
  String get showAgeSubtitle;

  /// Show distance toggle
  ///
  /// In en, this message translates to:
  /// **'Show Distance'**
  String get showDistance;

  /// Show distance subtitle
  ///
  /// In en, this message translates to:
  /// **'Display distance on your profile'**
  String get showDistanceSubtitle;

  /// Support section
  ///
  /// In en, this message translates to:
  /// **'Support & About'**
  String get sectionSupportAbout;

  /// Help & Support title
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// About title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutLabel;

  /// Rate us title
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get rateUs;

  /// About dialog title
  ///
  /// In en, this message translates to:
  /// **'About DatingApp'**
  String get aboutAppTitle;

  /// Version number
  ///
  /// In en, this message translates to:
  /// **'Version: 1.0.0'**
  String get versionNumber;

  /// About app description
  ///
  /// In en, this message translates to:
  /// **'Find your perfect match with our AI-powered dating app.'**
  String get aboutAppDescription;

  /// Made by team line
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️ by the DatingApp Team'**
  String get madeByTeam;

  /// Verification screen title
  ///
  /// In en, this message translates to:
  /// **'Verify Your Identity'**
  String get verifyIdentityTitle;

  /// Verification heading
  ///
  /// In en, this message translates to:
  /// **'Take a Selfie to Verify'**
  String get takeSelfieToVerify;

  /// Verification description
  ///
  /// In en, this message translates to:
  /// **'We compare your selfie to your profile photo to confirm it\'s really you. This keeps everyone safe.'**
  String get selfieVerifyDescription;

  /// Selfie tip 1
  ///
  /// In en, this message translates to:
  /// **'Good lighting, face clearly visible'**
  String get selfieTip1;

  /// Selfie tip 2
  ///
  /// In en, this message translates to:
  /// **'Look straight at camera'**
  String get selfieTip2;

  /// Selfie tip 3
  ///
  /// In en, this message translates to:
  /// **'No sunglasses, masks, or heavy filters'**
  String get selfieTip3;

  /// Attempts remaining
  ///
  /// In en, this message translates to:
  /// **'{count} attempt(s) remaining today'**
  String attemptsRemainingToday(int count);

  /// Take selfie button
  ///
  /// In en, this message translates to:
  /// **'Take Selfie'**
  String get takeSelfie;

  /// Preview heading
  ///
  /// In en, this message translates to:
  /// **'Looking good?'**
  String get lookingGood;

  /// Preview description
  ///
  /// In en, this message translates to:
  /// **'Make sure your face is clearly visible and matches your profile photo.'**
  String get selfiePreviewDescription;

  /// Verification loading
  ///
  /// In en, this message translates to:
  /// **'Verifying your identity...'**
  String get verifyingIdentity;

  /// Submit button
  ///
  /// In en, this message translates to:
  /// **'Submit for Verification'**
  String get submitForVerification;

  /// Retake button
  ///
  /// In en, this message translates to:
  /// **'Retake Photo'**
  String get retakePhoto;

  /// Verified result
  ///
  /// In en, this message translates to:
  /// **'Verified!'**
  String get verified;

  /// Under review result
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReview;

  /// Failed result
  ///
  /// In en, this message translates to:
  /// **'Verification Failed'**
  String get verificationFailedResult;

  /// Already verified heading
  ///
  /// In en, this message translates to:
  /// **'You\'re Already Verified!'**
  String get alreadyVerified;

  /// Already verified body
  ///
  /// In en, this message translates to:
  /// **'Your identity has been confirmed. Other users can see your blue verification badge.'**
  String get alreadyVerifiedDescription;

  /// Verified profile tooltip
  ///
  /// In en, this message translates to:
  /// **'Verified profile'**
  String get verifiedProfile;

  /// Get verified CTA
  ///
  /// In en, this message translates to:
  /// **'Get Verified'**
  String get getVerified;

  /// Profile 100% complete
  ///
  /// In en, this message translates to:
  /// **'Profile complete! 🎉'**
  String get profileComplete;

  /// Profile almost complete
  ///
  /// In en, this message translates to:
  /// **'Almost there — add a few more details'**
  String get profileAlmostThere;

  /// Profile looking good
  ///
  /// In en, this message translates to:
  /// **'Looking good — keep going!'**
  String get profileLookingGood;

  /// Profile low completeness
  ///
  /// In en, this message translates to:
  /// **'Add more info to get matches'**
  String get addMoreInfoForMatches;

  /// Complete label in ring
  ///
  /// In en, this message translates to:
  /// **'complete'**
  String get completeLabel;

  /// Add photo slot label
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// Failed to load placeholder
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// Network unavailable error
  ///
  /// In en, this message translates to:
  /// **'Network unavailable. Please check your connection.'**
  String get errorNetworkUnavailable;

  /// Session expired error
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get errorSessionExpired;

  /// Required field error
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get errorFieldRequired;

  /// Message load error
  ///
  /// In en, this message translates to:
  /// **'Failed to load messages: {error}'**
  String errorLoadingMessages(String error);

  /// Message send error
  ///
  /// In en, this message translates to:
  /// **'Error sending message: {error}'**
  String errorSendingMessage(String error);

  /// Profile tab label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTab;

  /// Settings tab label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// Empty discovery message
  ///
  /// In en, this message translates to:
  /// **'Check back later for new people'**
  String get noNewPeople;

  /// Connection error message
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again'**
  String get connectionError;

  /// Connected status
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// Connecting status
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// About section title
  ///
  /// In en, this message translates to:
  /// **'About DatingApp'**
  String get aboutApp;

  /// Account settings section
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// Privacy settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Control your privacy settings'**
  String get privacySettings;

  /// Phone number input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get onboardingPhoneHint;

  /// Verification screen title
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get onboardingVerifyCode;

  /// Verification in progress
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get onboardingVerifying;

  /// Code resent message
  ///
  /// In en, this message translates to:
  /// **'Code resent ({remaining} left)'**
  String onboardingCodeResent(int remaining);

  /// Country selector title
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get onboardingSelectCountry;

  /// First name screen title
  ///
  /// In en, this message translates to:
  /// **'What\'s your first name?'**
  String get onboardingFirstNameTitle;

  /// Birthday screen title
  ///
  /// In en, this message translates to:
  /// **'When\'s your birthday?'**
  String get onboardingBirthdayTitle;

  /// Gender screen title
  ///
  /// In en, this message translates to:
  /// **'What\'s your gender?'**
  String get onboardingGenderTitle;

  /// Orientation screen title
  ///
  /// In en, this message translates to:
  /// **'What\'s your orientation?'**
  String get onboardingOrientationTitle;

  /// Relationship goals title
  ///
  /// In en, this message translates to:
  /// **'What are you looking for?'**
  String get onboardingRelationshipGoalsTitle;

  /// Match preferences title
  ///
  /// In en, this message translates to:
  /// **'Match Preferences'**
  String get onboardingMatchPrefsTitle;

  /// Photos screen title
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get onboardingPhotosTitle;

  /// Lifestyle screen title
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get onboardingLifestyleTitle;

  /// Interests screen title
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get onboardingInterestsTitle;

  /// About me screen title
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get onboardingAboutMeTitle;

  /// Location screen title
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get onboardingLocationTitle;

  /// Location subtitle
  ///
  /// In en, this message translates to:
  /// **'We use your location to show you potential matches nearby'**
  String get onboardingLocationSubtitle;

  /// Enable location button
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get enableLocationButton;

  /// Maybe later button
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLaterButton;

  /// Notifications title
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get onboardingNotificationsTitle;

  /// Notifications subtitle
  ///
  /// In en, this message translates to:
  /// **'Get notified when someone likes you or sends a message'**
  String get onboardingNotificationsSubtitle;

  /// Enable notifications button
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotificationsButton;

  /// Complete title
  ///
  /// In en, this message translates to:
  /// **'You\'re All Set!'**
  String get onboardingCompleteTitle;

  /// Complete subtitle
  ///
  /// In en, this message translates to:
  /// **'Your profile is ready. Start discovering amazing people!'**
  String get onboardingCompleteSubtitle;

  /// Start discovering button
  ///
  /// In en, this message translates to:
  /// **'Start Discovering'**
  String get startDiscoveringButton;

  /// Photo added text
  ///
  /// In en, this message translates to:
  /// **'Photo {index} added (placeholder)'**
  String photoAdded(int index);

  /// Interests limit
  ///
  /// In en, this message translates to:
  /// **'Add up to {max} interests to show on your profile.'**
  String addUpToInterests(int max);

  /// No description provided for @verificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get a blue checkmark'**
  String get verificationSubtitle;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New matches and messages'**
  String get notificationsSubtitle;

  /// No description provided for @getMoreSparks.
  ///
  /// In en, this message translates to:
  /// **'Get more Sparks'**
  String get getMoreSparks;

  /// No description provided for @matchFound.
  ///
  /// In en, this message translates to:
  /// **'It\'s a match!'**
  String get matchFound;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sv'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sv':
      return AppLocalizationsSv();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
