import 'dart:convert';
import 'package:http/http.dart' as http;
import 'test_config.dart';

/// Modular Profile API helpers
/// Matches actual WizardController DTOs (WizardStepBasicInfoDto, etc.)

/// Update wizard step 1 (BasicInfo)
/// DTO: { firstName, lastName?, dateOfBirth, gender }
/// Contract: PATCH /api/wizard/step/1 → 200
Future<Map<String, dynamic>> updateWizardStep1(
  TestUser user, {
  required String firstName,
  String lastName = '',
  required String dateOfBirth,
  required String gender,
  // Legacy params kept for backward compat — ignored by backend
  String? location,
  String? bio,
}) async {
  final response = await http.patch(
    Uri.parse('${TestConfig.baseUrl}/api/wizard/step/1'),
    headers: {
      'Content-Type': 'application/json',
      ...user.authHeaders,
    },
    body: jsonEncode({
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
    }),
  ).timeout(TestConfig.apiTimeout);

  if (response.statusCode != 200) {
    throw Exception('Step 1 failed: ${response.statusCode} ${response.body}');
  }

  return jsonDecode(response.body);
}

/// Update wizard step 2 (Preferences)
/// DTO: { minAge, maxAge, maxDistance, preferredGender?, bio? }
/// Contract: PATCH /api/wizard/step/2 → 200
Future<Map<String, dynamic>> updateWizardStep2(
  TestUser user, {
  String? interestedIn,   // maps to preferredGender
  int minAge = 18,
  int maxAge = 99,
  int maxDistance = 50,
  String? bio,
  // Legacy aliases
  int? ageRangeMin,
  int? ageRangeMax,
  List<String>? interests, // ignored — interests are in step 5
}) async {
  final response = await http.patch(
    Uri.parse('${TestConfig.baseUrl}/api/wizard/step/2'),
    headers: {
      'Content-Type': 'application/json',
      ...user.authHeaders,
    },
    body: jsonEncode({
      'minAge': ageRangeMin ?? minAge,
      'maxAge': ageRangeMax ?? maxAge,
      'maxDistance': maxDistance,
      if (interestedIn != null) 'preferredGender': interestedIn,
      if (bio != null) 'bio': bio,
    }),
  ).timeout(TestConfig.apiTimeout);

  if (response.statusCode != 200) {
    throw Exception('Step 2 failed: ${response.statusCode} ${response.body}');
  }

  return jsonDecode(response.body);
}

/// Update wizard step 3 (Photos — marks profile as Ready)
/// DTO: { photoUrls: ["url1", ...] }
/// Contract: PATCH /api/wizard/step/3 → 200
Future<Map<String, dynamic>> updateWizardStep3(
  TestUser user, {
  List<String>? photoUrls,
}) async {
  final urls = photoUrls ?? ['https://example.com/photos/test-photo-1.jpg'];

  final response = await http.patch(
    Uri.parse('${TestConfig.baseUrl}/api/wizard/step/3'),
    headers: {
      'Content-Type': 'application/json',
      ...user.authHeaders,
    },
    body: jsonEncode({
      'photoUrls': urls,
    }),
  ).timeout(TestConfig.apiTimeout);

  if (response.statusCode != 200) {
    throw Exception('Step 3 failed: ${response.statusCode} ${response.body}');
  }

  final data = jsonDecode(response.body);
  // Extract profileId from ApiResponse wrapper
  user.profileId = data['data']?['id'] ?? data['id'];
  return data;
}

/// Update wizard step 4 (Identity & Goals — optional)
/// DTO: { sexualOrientation?, relationshipType? }
/// Contract: PATCH /api/wizard/step/4 → 200
Future<Map<String, dynamic>> updateWizardStep4(
  TestUser user, {
  String? sexualOrientation,
  String? relationshipType,
}) async {
  final response = await http.patch(
    Uri.parse('${TestConfig.baseUrl}/api/wizard/step/4'),
    headers: {
      'Content-Type': 'application/json',
      ...user.authHeaders,
    },
    body: jsonEncode({
      if (sexualOrientation != null) 'sexualOrientation': sexualOrientation,
      if (relationshipType != null) 'relationshipType': relationshipType,
    }),
  ).timeout(TestConfig.apiTimeout);

  if (response.statusCode != 200) {
    throw Exception('Step 4 failed: ${response.statusCode} ${response.body}');
  }

  return jsonDecode(response.body);
}

/// Update wizard step 5 (About Me — optional)
/// DTO: { interests[], smokingStatus?, drinkingStatus?, wantsChildren?,
///        occupation?, company?, education?, school? }
/// Contract: PATCH /api/wizard/step/5 → 200
Future<Map<String, dynamic>> updateWizardStep5(
  TestUser user, {
  List<String> interests = const [],
  String? smokingStatus,
  String? drinkingStatus,
  bool? wantsChildren,
  String? occupation,
  String? company,
  String? education,
  String? school,
}) async {
  final response = await http.patch(
    Uri.parse('${TestConfig.baseUrl}/api/wizard/step/5'),
    headers: {
      'Content-Type': 'application/json',
      ...user.authHeaders,
    },
    body: jsonEncode({
      'interests': interests,
      if (smokingStatus != null) 'smokingStatus': smokingStatus,
      if (drinkingStatus != null) 'drinkingStatus': drinkingStatus,
      if (wantsChildren != null) 'wantsChildren': wantsChildren,
      if (occupation != null) 'occupation': occupation,
      if (company != null) 'company': company,
      if (education != null) 'education': education,
      if (school != null) 'school': school,
    }),
  ).timeout(TestConfig.apiTimeout);

  if (response.statusCode != 200) {
    throw Exception('Step 5 failed: ${response.statusCode} ${response.body}');
  }

  return jsonDecode(response.body);
}

/// Get current user profile
/// Contract: GET /api/profiles/me → 200
Future<Map<String, dynamic>> getMyProfile(TestUser user) async {
  final response = await http.get(
    Uri.parse('${TestConfig.baseUrl}/api/profiles/me'),
    headers: user.authHeaders,
  ).timeout(TestConfig.apiTimeout);

  if (response.statusCode != 200) {
    throw Exception('Get profile failed: ${response.statusCode} ${response.body}');
  }

  final body = jsonDecode(response.body);
  return body['data'] ?? body;
}

/// Update profile (for testing edits after onboarding)
/// Contract: PUT /api/profiles/me → 200
Future<Map<String, dynamic>> updateProfile(
  TestUser user,
  Map<String, dynamic> updates,
) async {
  final response = await http.put(
    Uri.parse('${TestConfig.baseUrl}/api/profiles/me'),
    headers: {
      'Content-Type': 'application/json',
      ...user.authHeaders,
    },
    body: jsonEncode(updates),
  ).timeout(TestConfig.apiTimeout);

  if (response.statusCode != 200) {
    throw Exception('Update profile failed: ${response.statusCode} ${response.body}');
  }

  final body = jsonDecode(response.body);
  return body['data'] ?? body;
}

/// Helper: Complete the minimum onboarding flow (steps 1-3)
Future<TestUser> completeOnboarding(
  TestUser user, {
  String? firstName,
  String? lastName,
}) async {
  await updateWizardStep1(
    user,
    firstName: firstName ?? 'Test',
    lastName: lastName ?? 'User',
    dateOfBirth: '1995-01-15',
    gender: 'Male',
  );

  await updateWizardStep2(
    user,
    interestedIn: 'Female',
    minAge: 22,
    maxAge: 35,
    maxDistance: 50,
    bio: 'Test bio for integration testing',
  );

  await updateWizardStep3(user);

  return user;
}

/// Helper: Complete full onboarding (all 5 steps)
Future<TestUser> completeFullOnboarding(
  TestUser user, {
  String? firstName,
  String? lastName,
}) async {
  await completeOnboarding(user, firstName: firstName, lastName: lastName);

  await updateWizardStep4(
    user,
    sexualOrientation: 'Straight',
    relationshipType: 'Relationship',
  );

  await updateWizardStep5(
    user,
    interests: ['hiking', 'coffee', 'tech'],
    occupation: 'Software Engineer',
    education: "Bachelor's",
  );

  return user;
}
