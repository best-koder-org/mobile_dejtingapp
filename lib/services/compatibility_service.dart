/// Model for a single compatibility question.
class CompatibilityQuestion {
  final String id;
  final String category;
  final String text;
  final List<String> options;

  const CompatibilityQuestion({
    required this.id,
    required this.category,
    required this.text,
    required this.options,
  });
}

/// Abstract interface for the compatibility-questions service.
///
/// Keeping it abstract makes it trivially mockable in tests without
/// code-generation — just extend and override the two methods.
abstract class CompatibilityService {
  /// Returns the list of compatibility questions to display.
  Future<List<CompatibilityQuestion>> fetchQuestions();

  /// Submits the user's answers (questionId → chosen option).
  /// Throws on network / server errors.
  Future<void> submitAnswers(Map<String, String> answers);
}

/// Default implementation that talks to the real backend.
///
/// Swap this out in tests by passing a mock to
/// [CompatibilityQuestionsScreen].
class DefaultCompatibilityService implements CompatibilityService {
  const DefaultCompatibilityService();

  @override
  Future<List<CompatibilityQuestion>> fetchQuestions() async {
    // In production this would hit an API endpoint.
    // For now, return a curated set of hard-coded questions so the
    // screen is usable before the backend ships the endpoint.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const [
      CompatibilityQuestion(
        id: 'q1',
        category: 'Values',
        text: 'How important is religion / spirituality to you?',
        options: ['Very important', 'Somewhat important', 'Not important'],
      ),
      CompatibilityQuestion(
        id: 'q2',
        category: 'Values',
        text: 'Do you want children in the future?',
        options: ['Yes', 'No', 'Open to it', 'Already have'],
      ),
      CompatibilityQuestion(
        id: 'q3',
        category: 'Lifestyle',
        text: 'How do you prefer to spend your weekends?',
        options: ['Outdoors', 'Cosy at home', 'Social events', 'A mix'],
      ),
      CompatibilityQuestion(
        id: 'q4',
        category: 'Lifestyle',
        text: 'How often do you travel?',
        options: ['Multiple times a year', 'Once a year', 'Rarely', 'Never'],
      ),
      CompatibilityQuestion(
        id: 'q5',
        category: 'Personality',
        text: 'Would you describe yourself as more introverted or extroverted?',
        options: ['Introverted', 'Extroverted', 'Ambivert'],
      ),
      CompatibilityQuestion(
        id: 'q6',
        category: 'Personality',
        text: 'What is your conflict resolution style?',
        options: ['Talk it out immediately', 'Need space first', 'Avoid conflict', 'Depends'],
      ),
    ];
  }

  @override
  Future<void> submitAnswers(Map<String, String> answers) async {
    // TODO(backend): POST /api/v1/profile/compatibility with answers payload.
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}
