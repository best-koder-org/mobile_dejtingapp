/// Central data bag for the entire onboarding wizard.
///
/// **All wizard screens write to this single object.**
/// To add a field: just add it here — no other files change.
/// To remove a field: delete it here, remove the UI that sets it.
///
/// This is intentionally a mutable class (not immutable/freezed) because
/// the wizard is a multi-step form where each screen mutates one section.
class OnboardingData {
  // ── Step: Phone Auth ───────────────────────────────────────
  String? phoneNumber;
  String? countryCode;
  String? firebaseIdToken;
  String? keycloakAccessToken;


  // ── Step: First Name ───────────────────────────────────────
  String? firstName;

  // ── Step: Birthday ─────────────────────────────────────────
  DateTime? dateOfBirth;

  // ── Step: Gender ───────────────────────────────────────────
  String? gender; // 'Man', 'Woman', 'Non-binary', etc.
  bool genderVisible = true;

  // ── Step: Orientation ──────────────────────────────────────
  List<String> orientation = []; // ['Straight'], ['Bisexual', 'Queer'], etc.
  bool orientationVisible = true;

  // ── Step: Relationship Goals ───────────────────────────────
  String? relationshipGoal; // 'Relationship', 'Casual', 'Friendship', etc.

  // ── Step: Match Preferences ────────────────────────────────
  int minAge = 18;
  int maxAge = 99;
  int maxDistanceKm = 50;
  String? preferredGender;

  // ── Step: Lifestyle ────────────────────────────────────────
  Map<String, String> lifestyle = {}; // e.g. {'drinking': 'Sometimes', ...}

  // ── Step: Interests ────────────────────────────────────────
  List<String> interests = [];

  // ── Step: About Me ─────────────────────────────────────────
  String? bio;
  String? jobTitle;
  String? company;
  String? school;
  String? hometown;
  String? communicationStyle;
  String? loveLanguage;
  String? education;

  // ── Step: Photos ───────────────────────────────────────────
  List<String> photoUrls = []; // URLs after upload to photo-service

  // ── Step: Location Permission ──────────────────────────────
  bool locationGranted = false;

  // ── Step: Notification Permission ──────────────────────────
  bool notificationsGranted = false;

  // ── Validation ─────────────────────────────────────────────

  /// Minimum required data to submit to UserService.
  bool get isMinimumComplete =>
      firstName != null &&
      dateOfBirth != null &&
      gender != null;

  /// Ideal: has photo(s) too.
  bool get isFullyComplete =>
      isMinimumComplete && photoUrls.isNotEmpty;

  // ── API serialization ──────────────────────────────────────

  /// Maps to UserService WizardStepBasicInfoDto (PATCH step/1).
  Map<String, dynamic> toBasicInfoPayload() => {
        'firstName': firstName ?? '',
        'lastName': '', // Not collected in current wizard
        'dateOfBirth': dateOfBirth?.toIso8601String() ?? '',
        'gender': gender ?? '',
      };

  /// Maps to UserService WizardStepPreferencesDto (PATCH step/2).
  Map<String, dynamic> toPreferencesPayload() => {
        'minAge': minAge,
        'maxAge': maxAge,
        'maxDistance': maxDistanceKm,
        'preferredGender': preferredGender,
        'bio': bio,
      };

  /// Maps to UserService WizardStepPhotosDto (PATCH step/3).
  Map<String, dynamic> toPhotosPayload() => {
        'photoUrls': photoUrls,
      };

  @override
  String toString() =>
      'OnboardingData(name=$firstName, dob=$dateOfBirth, gender=$gender, '
      'orientation=$orientation, goal=$relationshipGoal, '
      'photos=${photoUrls.length}, interests=${interests.length})';
}
