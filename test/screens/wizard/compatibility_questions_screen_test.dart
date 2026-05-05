import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/wizard/compatibility_questions_screen.dart';
import 'package:dejtingapp/services/compatibility_service.dart';
import '../../helpers/onboarding_test_helper.dart';

// ── Fakes ──────────────────────────────────────────────────────────────────

/// A stub [CompatibilityService] that returns a fixed list of questions.
class _FakeCompatibilityService implements CompatibilityService {
  _FakeCompatibilityService({List<CompatibilityQuestion>? questions})
      : _questions = questions ?? _defaultQuestions;

  final List<CompatibilityQuestion> _questions;
  int submitCallCount = 0;
  Map<String, String>? lastSubmittedAnswers;

  static const List<CompatibilityQuestion> _defaultQuestions = [
    CompatibilityQuestion(
      id: 'q1',
      category: 'Values',
      text: 'How important is religion?',
      options: ['Very important', 'Not important'],
    ),
    CompatibilityQuestion(
      id: 'q2',
      category: 'Values',
      text: 'Do you want children?',
      options: ['Yes', 'No'],
    ),
    CompatibilityQuestion(
      id: 'q3',
      category: 'Lifestyle',
      text: 'Weekend preference?',
      options: ['Outdoors', 'Home'],
    ),
  ];

  @override
  Future<List<CompatibilityQuestion>> fetchQuestions() async => _questions;

  @override
  Future<void> submitAnswers(Map<String, String> answers) async {
    submitCallCount++;
    lastSubmittedAnswers = Map<String, String>.from(answers);
  }
}

/// A [CompatibilityService] that throws on [fetchQuestions].
class _ErrorCompatibilityService implements CompatibilityService {
  @override
  Future<List<CompatibilityQuestion>> fetchQuestions() async {
    throw Exception('Network error');
  }

  @override
  Future<void> submitAnswers(Map<String, String> answers) async {}
}

/// A [CompatibilityService] that never completes [fetchQuestions]
/// (used to verify the loading indicator).
class _LoadingCompatibilityService implements CompatibilityService {
  @override
  Future<List<CompatibilityQuestion>> fetchQuestions() async {
    await Future<void>.delayed(const Duration(seconds: 60)); // effectively ∞
    return const [];
  }

  @override
  Future<void> submitAnswers(Map<String, String> answers) async {}
}

// ── Helpers ────────────────────────────────────────────────────────────────

Widget buildSubject({CompatibilityService? service}) {
  return buildOnboardingTestHarness(
    screen: CompatibilityQuestionsScreen(
      service: service ?? _FakeCompatibilityService(),
    ),
    routeName: '/onboarding/compatibility',
    extraRoutes: {
      '/onboarding/compatibility': (_) =>
          const Scaffold(body: Text('compatibility')),
    },
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('CompatibilityQuestionsScreen', () {
    // ── 1. Questions render in category groups ────────────────────────────
    testWidgets('renders questions grouped by category', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Category headers
      expect(find.text('Values'), findsOneWidget);
      expect(find.text('Lifestyle'), findsOneWidget);

      // Question texts
      expect(find.text('How important is religion?'), findsOneWidget);
      expect(find.text('Do you want children?'), findsOneWidget);
      expect(find.text('Weekend preference?'), findsOneWidget);

      // Option chips
      expect(find.text('Very important'), findsOneWidget);
      expect(find.text('Outdoors'), findsOneWidget);
    });

    // ── 2. Selecting an option records the answer ─────────────────────────
    testWidgets('selecting an option switches button to Continue',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Initially shows "Skip for now"
      expect(find.text('Skip for now'), findsOneWidget);

      // Tap the first option of the first question
      await tester.tap(find.text('Very important'));
      await tester.pump();

      // Now the button shows "Continue"
      expect(find.text('Continue'), findsOneWidget);
    });

    // ── 3. Submit invokes the service ─────────────────────────────────────
    testWidgets('tapping Continue calls submitAnswers on the service',
        (tester) async {
      final service = _FakeCompatibilityService();
      await tester.pumpWidget(buildSubject(service: service));
      await tester.pumpAndSettle();

      // Select an answer so the submit button activates
      await tester.tap(find.text('Yes'));
      await tester.pump();

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(service.submitCallCount, equals(1));
      expect(service.lastSubmittedAnswers, isNotNull);
      expect(service.lastSubmittedAnswers!['q2'], equals('Yes'));
    });

    // ── 4. Skip advances without recording ───────────────────────────────
    testWidgets('tapping Skip in app bar does NOT call submitAnswers',
        (tester) async {
      final service = _FakeCompatibilityService();
      await tester.pumpWidget(buildSubject(service: service));
      await tester.pumpAndSettle();

      // Tap the Skip button in the app bar (no answers selected)
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(service.submitCallCount, equals(0));
    });

    testWidgets('tapping Skip for now button also does NOT call submitAnswers',
        (tester) async {
      final service = _FakeCompatibilityService();
      await tester.pumpWidget(buildSubject(service: service));
      await tester.pumpAndSettle();

      // "Skip for now" bottom button is visible when nothing is selected
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();

      expect(service.submitCallCount, equals(0));
    });

    // ── 5. Loading state shown during fetch ───────────────────────────────
    testWidgets('shows loading indicator while questions are being fetched',
        (tester) async {
      await tester.pumpWidget(buildSubject(
        service: _LoadingCompatibilityService(),
      ));
      // Only pump once — questions are never resolved
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    // ── 6. Error state shown when fetch fails ─────────────────────────────
    testWidgets('shows error message and retry button when fetch fails',
        (tester) async {
      await tester.pumpWidget(buildSubject(
        service: _ErrorCompatibilityService(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Could not load questions'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    // ── Extra: progress bar and back navigation ───────────────────────────
    testWidgets('has progress bar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('has back navigation icon', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('has screen:onboarding-compatibility semantics label',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              (w as Semantics).properties.label ==
                  'screen:onboarding-compatibility',
        ),
        findsOneWidget,
      );
    });
  });
}
