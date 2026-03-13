import 'package:flutter_test/flutter_test.dart';
import 'helpers/test_config.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/profile_helpers.dart';

/// T021: Profile Onboarding Integration Test
/// Tests CONTRACTS against actual WizardController (5-step wizard)
///
/// Wizard steps:
///   1. BasicInfo  (firstName, lastName, dateOfBirth, gender)
///   2. Preferences (minAge, maxAge, maxDistance, preferredGender, bio)
///   3. Photos     (photoUrls) — marks profile Ready
///   4. Identity   (sexualOrientation, relationshipType) — optional
///   5. AboutMe    (interests, lifestyle, work, education) — optional

void main() {
  group('T021 - Profile Onboarding Contracts', () {
    late TestUser testUser;

    setUp(() {
      testUser = TestUser.random();
    });

    test('Contract: User can register and get auth token', () async {
      await registerUser(testUser);

      expect(testUser.isAuthenticated, true, reason: 'Should have access token');
      expect(testUser.userId, isNotNull, reason: 'Should have userId');
    });

    test('Contract: Wizard Step 1 accepts basic info', () async {
      await registerUser(testUser);

      final result = await updateWizardStep1(
        testUser,
        firstName: 'Integration',
        dateOfBirth: '1990-05-15',
        gender: 'Male',
      );

      expect(result, isNotEmpty, reason: 'Should return profile data');
    });

    test('Contract: Wizard Step 2 accepts preferences', () async {
      await registerUser(testUser);
      await updateWizardStep1(
        testUser,
        firstName: 'Test',
        dateOfBirth: '1992-03-20',
        gender: 'Female',
      );

      final result = await updateWizardStep2(
        testUser,
        interestedIn: 'Male',
        minAge: 25,
        maxAge: 40,
        maxDistance: 30,
      );

      expect(result, isNotEmpty);
    });

    test('Contract: Wizard Step 3 marks profile ready', () async {
      await registerUser(testUser);
      await updateWizardStep1(
        testUser,
        firstName: 'Ready',
        dateOfBirth: '1988-11-10',
        gender: 'Male',
      );
      await updateWizardStep2(
        testUser,
        interestedIn: 'Female',
        minAge: 22,
        maxAge: 35,
        maxDistance: 50,
      );

      final result = await updateWizardStep3(testUser);

      expect(result, isNotEmpty);
      expect(testUser.profileId, isNotNull, reason: 'Should have profileId');
    });

    test('Contract: Wizard Step 4 accepts identity (optional)', () async {
      await registerUser(testUser);
      await completeOnboarding(testUser);

      final result = await updateWizardStep4(
        testUser,
        sexualOrientation: 'Straight',
        relationshipType: 'Relationship',
      );

      expect(result, isNotEmpty);
    });

    test('Contract: Wizard Step 5 accepts about-me (optional)', () async {
      await registerUser(testUser);
      await completeOnboarding(testUser);

      final result = await updateWizardStep5(
        testUser,
        interests: ['hiking', 'coffee', 'photography'],
        occupation: 'Engineer',
        education: "Master's",
        drinkingStatus: 'Socially',
      );

      expect(result, isNotEmpty);
    });

    test('Contract: Can retrieve completed profile', () async {
      await registerUser(testUser);
      await completeOnboarding(testUser);

      final profile = await getMyProfile(testUser);

      expect(profile, isNotEmpty);
      // Profile should indicate ready status after step 3
      expect(profile['onboardingStatus'], anyOf(
        equals('Ready'),
        equals('ready'),
        equals(1),
        equals(2), // Might use numeric enum
      ), reason: 'Profile should be ready after completing wizard');
    });

    test('Flow: Full 5-step onboarding journey', () async {
      await registerUser(testUser);

      // Step 1: Basic Info
      await updateWizardStep1(
        testUser,
        firstName: 'Journey',
        lastName: 'Tester',
        dateOfBirth: '1993-07-18',
        gender: 'Male',
      );

      // Step 2: Preferences
      await updateWizardStep2(
        testUser,
        interestedIn: 'Female',
        minAge: 24,
        maxAge: 34,
        maxDistance: 40,
        bio: 'Testing the full onboarding journey',
      );

      // Step 3: Photos (marks ready)
      await updateWizardStep3(testUser);

      // Step 4: Identity (optional)
      await updateWizardStep4(
        testUser,
        sexualOrientation: 'Bisexual',
        relationshipType: 'Casual',
      );

      // Step 5: About Me (optional)
      await updateWizardStep5(
        testUser,
        interests: ['hiking', 'coffee', 'books'],
        smokingStatus: 'Never',
        drinkingStatus: 'Socially',
        occupation: 'Tester',
        education: "Bachelor's",
      );

      // Verify: Profile is complete
      final profile = await getMyProfile(testUser);
      expect(profile['firstName'], equals('Journey'));
      expect(testUser.hasProfile, true);
    });

    test('Resilience: Can update profile after onboarding', () async {
      await registerUser(testUser);
      await completeOnboarding(testUser);

      final updated = await updateProfile(testUser, {
        'bio': 'Updated bio after onboarding',
      });

      expect(updated, isNotEmpty);
    });

    test('Error: Invalid data rejected', () async {
      await registerUser(testUser);

      try {
        await updateWizardStep1(
          testUser,
          firstName: '',          // Empty name should fail
          dateOfBirth: '2025-01-01', // Future date / too young
          gender: 'InvalidGender',
        );

        fail('Should have thrown validation error');
      } catch (e) {
        expect(e.toString(), contains('failed'),
          reason: 'Should reject invalid data');
      }
    });
  });
}
