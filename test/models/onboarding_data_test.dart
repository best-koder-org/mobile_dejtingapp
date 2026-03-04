import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/models/onboarding_data.dart';

void main() {
  group('OnboardingData', () {
    late OnboardingData data;

    setUp(() {
      data = OnboardingData();
    });

    group('defaults', () {
      test('all nullable fields are null', () {
        expect(data.firstName, isNull);
        expect(data.dateOfBirth, isNull);
        expect(data.gender, isNull);
        expect(data.relationshipGoal, isNull);
        expect(data.preferredGender, isNull);
        expect(data.bio, isNull);
        expect(data.jobTitle, isNull);
      });

      test('lists start empty', () {
        expect(data.orientation, isEmpty);
        expect(data.interests, isEmpty);
        expect(data.photoUrls, isEmpty);
      });

      test('lifestyle map starts empty', () {
        expect(data.lifestyle, isEmpty);
      });

      test('age range defaults', () {
        expect(data.minAge, 18);
        expect(data.maxAge, 99);
        expect(data.maxDistanceKm, 50);
      });

      test('visibility defaults to true', () {
        expect(data.genderVisible, isTrue);
        expect(data.orientationVisible, isTrue);
      });

      test('permissions default to false', () {
        expect(data.locationGranted, isFalse);
        expect(data.notificationsGranted, isFalse);
      });
    });

    group('isMinimumComplete', () {
      test('false when empty', () {
        expect(data.isMinimumComplete, isFalse);
      });

      test('false when only firstName set', () {
        data.firstName = 'Alice';
        expect(data.isMinimumComplete, isFalse);
      });

      test('true when firstName + dateOfBirth + gender set', () {
        data.firstName = 'Alice';
        data.dateOfBirth = DateTime(2000, 1, 15);
        data.gender = 'Woman';
        expect(data.isMinimumComplete, isTrue);
      });
    });

    group('isFullyComplete', () {
      test('false when minimum complete but no photos', () {
        data.firstName = 'Alice';
        data.dateOfBirth = DateTime(2000, 1, 15);
        data.gender = 'Woman';
        expect(data.isFullyComplete, isFalse);
      });

      test('true when minimum complete + photos', () {
        data.firstName = 'Alice';
        data.dateOfBirth = DateTime(2000, 1, 15);
        data.gender = 'Woman';
        data.photoUrls = ['https://example.com/photo1.jpg'];
        expect(data.isFullyComplete, isTrue);
      });
    });

    group('toBasicInfoPayload', () {
      test('serializes correctly', () {
        data.firstName = 'Bob';
        data.dateOfBirth = DateTime(1995, 6, 15);
        data.gender = 'Man';

        final payload = data.toBasicInfoPayload();
        expect(payload['firstName'], 'Bob');
        expect(payload['lastName'], '');
        expect(payload['dateOfBirth'], '1995-06-15T00:00:00.000');
        expect(payload['gender'], 'Man');
      });

      test('uses empty strings when null', () {
        final payload = data.toBasicInfoPayload();
        expect(payload['firstName'], '');
        expect(payload['gender'], '');
      });
    });

    group('toPreferencesPayload', () {
      test('serializes age range and gender', () {
        data.minAge = 22;
        data.maxAge = 35;
        data.maxDistanceKm = 25;
        data.preferredGender = 'Women';
        data.bio = 'Hello world';

        final payload = data.toPreferencesPayload();
        expect(payload['minAge'], 22);
        expect(payload['maxAge'], 35);
        expect(payload['maxDistance'], 25);
        expect(payload['preferredGender'], 'Women');
        expect(payload['bio'], 'Hello world');
      });
    });

    group('toPhotosPayload', () {
      test('serializes photo URLs', () {
        data.photoUrls = ['url1', 'url2'];
        final payload = data.toPhotosPayload();
        expect(payload['photoUrls'], ['url1', 'url2']);
      });
    });

    group('toIdentityPayload', () {
      test('joins orientation list', () {
        data.orientation = ['Bisexual', 'Queer'];
        data.relationshipGoal = 'Long-term partner';

        final payload = data.toIdentityPayload();
        expect(payload['sexualOrientation'], 'Bisexual, Queer');
        expect(payload['relationshipType'], 'Long-term partner');
      });

      test('null when orientation empty', () {
        final payload = data.toIdentityPayload();
        expect(payload['sexualOrientation'], isNull);
        expect(payload['relationshipType'], isNull);
      });
    });

    group('toAboutMePayload', () {
      test('serializes interests as list (not comma-separated)', () {
        data.interests = ['Hiking', 'Coffee', 'Reading'];

        final payload = data.toAboutMePayload();
        expect(payload['interests'], isA<List>());
        expect(payload['interests'], ['Hiking', 'Coffee', 'Reading']);
      });

      test('serializes lifestyle and work fields', () {
        data.lifestyle = {'smoking': 'Never', 'drinking': 'Sometimes'};
        data.jobTitle = 'Engineer';
        data.company = 'ACME';
        data.education = 'Bachelors';
        data.school = 'MIT';

        final payload = data.toAboutMePayload();
        expect(payload['smokingStatus'], 'Never');
        expect(payload['drinkingStatus'], 'Sometimes');
        expect(payload['occupation'], 'Engineer');
        expect(payload['company'], 'ACME');
        expect(payload['education'], 'Bachelors');
        expect(payload['school'], 'MIT');
      });
    });

    group('hasIdentityData', () {
      test('false when empty', () {
        expect(data.hasIdentityData, isFalse);
      });

      test('true with orientation', () {
        data.orientation = ['Straight'];
        expect(data.hasIdentityData, isTrue);
      });

      test('true with relationship goal', () {
        data.relationshipGoal = 'Casual';
        expect(data.hasIdentityData, isTrue);
      });
    });

    group('hasAboutMeData', () {
      test('false when empty', () {
        expect(data.hasAboutMeData, isFalse);
      });

      test('true with interests', () {
        data.interests = ['Yoga'];
        expect(data.hasAboutMeData, isTrue);
      });

      test('true with lifestyle', () {
        data.lifestyle = {'smoking': 'Never'};
        expect(data.hasAboutMeData, isTrue);
      });

      test('true with jobTitle', () {
        data.jobTitle = 'Dev';
        expect(data.hasAboutMeData, isTrue);
      });
    });

    test('toString includes key fields', () {
      data.firstName = 'Alice';
      data.gender = 'Woman';
      data.interests = ['A', 'B'];
      final s = data.toString();
      expect(s, contains('Alice'));
      expect(s, contains('Woman'));
      expect(s, contains('interests=2'));
    });
  });
}
