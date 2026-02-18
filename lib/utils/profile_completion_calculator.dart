import 'package:flutter/material.dart';

class ProfileCompletionCalculator {
  static int calculateProfileCompletion({
    required String firstName,
    required String lastName,
    required String bio,
    required List<String> photoUrls,
    required List<String> interests,
    String? city,
    String? occupation,
    String? education,
    String? gender,
    String? lookingFor,
    String? relationshipType,
    String? drinking,
    String? smoking,
    String? workout,
    String? height,
    List<String>? languages,
  }) {
    int completedFields = 0;
    int totalFields = 15; // Total important fields for profile completion

    // Essential fields (worth more points)
    if (firstName.isNotEmpty) completedFields++;
    if (lastName.isNotEmpty) completedFields++;
    if (bio.isNotEmpty && bio.length >= 50) {
      completedFields += 2; // Bio is worth 2 points
    }
    if (photoUrls.isNotEmpty) {
      completedFields += 2; // At least one photo is worth 2 points
    }
    if (photoUrls.length >= 3) {
      completedFields++; // Multiple photos get bonus point
    }
    if (interests.length >= 3) {
      completedFields += 2; // Interests are important for matching
    }

    // Additional important fields
    if (city?.isNotEmpty == true) completedFields++;
    if (occupation?.isNotEmpty == true) completedFields++;
    if (education?.isNotEmpty == true) completedFields++;
    if (gender?.isNotEmpty == true) completedFields++;
    if (lookingFor?.isNotEmpty == true) completedFields++;

    // Lifestyle fields
    if (relationshipType?.isNotEmpty == true) completedFields++;
    if (drinking?.isNotEmpty == true) completedFields++;
    if (smoking?.isNotEmpty == true) completedFields++;
    if (workout?.isNotEmpty == true) completedFields++;

    // Calculate percentage
    return ((completedFields / totalFields) * 100).round().clamp(0, 100);
  }

  static String getProfileCompletionMessage(int percentage) {
    if (percentage < 30) {
      return 'Let\'s get started! Add some photos and tell us about yourself.';
    } else if (percentage < 50) {
      return 'Good start! Complete your profile to get better matches.';
    } else if (percentage < 70) {
      return 'Looking good! Add more details to increase your match potential.';
    } else if (percentage < 90) {
      return 'Almost there! Complete a few more sections to maximize your profile.';
    } else if (percentage < 100) {
      return 'Excellent! Just a few finishing touches and you\'ll be all set.';
    } else {
      return 'Perfect! Your complete profile will attract more quality matches.';
    }
  }

  static List<String> getCompletionSuggestions({
    required String bio,
    required List<String> photoUrls,
    required List<String> interests,
    String? city,
    String? occupation,
    String? education,
    String? gender,
    String? lookingFor,
    String? relationshipType,
    String? drinking,
    String? smoking,
    String? workout,
  }) {
    List<String> suggestions = [];

    if (photoUrls.isEmpty) {
      suggestions.add('Add at least one photo');
    } else if (photoUrls.length < 3) {
      suggestions.add('Add more photos (${photoUrls.length}/9)');
    }

    if (bio.isEmpty) {
      suggestions.add('Write something about yourself in your bio');
    } else if (bio.length < 50) {
      suggestions.add('Expand your bio (${bio.length}/50+ characters)');
    }

    if (interests.length < 3) {
      suggestions.add('Add more interests (${interests.length}/10)');
    }

    if (city?.isEmpty != false) {
      suggestions.add('Add your city');
    }

    if (occupation?.isEmpty != false) {
      suggestions.add('Add your job title');
    }

    if (education?.isEmpty != false) {
      suggestions.add('Add your education level');
    }

    if (gender?.isEmpty != false) {
      suggestions.add('Specify your gender');
    }

    if (lookingFor?.isEmpty != false) {
      suggestions.add('Specify who you\'re looking for');
    }

    if (relationshipType?.isEmpty != false) {
      suggestions.add('Add what type of relationship you\'re seeking');
    }

    if (drinking?.isEmpty != false) {
      suggestions.add('Add your drinking preference');
    }

    if (smoking?.isEmpty != false) {
      suggestions.add('Add your smoking preference');
    }

    if (workout?.isEmpty != false) {
      suggestions.add('Add your workout frequency');
    }

    return suggestions.take(3).toList(); // Return top 3 suggestions
  }

  static Color getCompletionColor(int percentage) {
    if (percentage < 50) {
      return const Color(0xFFEF4444); // Red
    } else if (percentage < 80) {
      return const Color(0xFFF59E0B); // Orange
    } else {
      return const Color(0xFF10B981); // Green
    }
  }

  static String getMatchQualityBonus(int percentage) {
    if (percentage < 50) {
      return 'Complete your profile to see more potential matches';
    } else if (percentage < 80) {
      return '+25% better match quality with complete profile';
    } else if (percentage < 100) {
      return '+50% better match quality - almost there!';
    } else {
      return '+75% better match quality - maximum profile strength!';
    }
  }
}
