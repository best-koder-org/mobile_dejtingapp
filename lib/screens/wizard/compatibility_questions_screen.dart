import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/compatibility_service.dart';
import '../../theme/app_theme.dart';

/// Compatibility Questions Screen — grouped multi-choice questions.
///
/// Fetches questions from [CompatibilityService] on first build, lets the
/// user pick one option per question, then submits via the same service.
/// Skipping is allowed at any time and navigates forward without submitting.
class CompatibilityQuestionsScreen extends StatefulWidget {
  /// Allows injecting a custom (e.g. mock) service in tests.
  final CompatibilityService service;

  const CompatibilityQuestionsScreen({
    super.key,
    this.service = const DefaultCompatibilityService(),
  });

  @override
  State<CompatibilityQuestionsScreen> createState() =>
      _CompatibilityQuestionsScreenState();
}

class _CompatibilityQuestionsScreenState
    extends State<CompatibilityQuestionsScreen> {
  // ── State ──────────────────────────────────────────────────────────────
  List<CompatibilityQuestion>? _questions;
  bool _loading = true;
  String? _error;
  bool _submitting = false;

  /// questionId → chosen option value
  final Map<String, String> _answers = {};

  // ── Lifecycle ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final questions = await widget.service.fetchQuestions();
      if (mounted) {
        setState(() {
          _questions = questions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────
  void _selectOption(String questionId, String option) {
    setState(() {
      _answers[questionId] = option;
    });
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await widget.service.submitAnswers(Map<String, String>.from(_answers));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
        _goNext();
      }
    }
  }

  void _skip() {
    _goNext();
  }

  void _goNext() {
    OnboardingProvider.of(context).goNext(context);
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasAnyAnswer = _answers.isNotEmpty;

    return Semantics(
      label: 'screen:onboarding-compatibility',
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: _submitting ? null : _skip,
              child: Text(
                l10n.skipButton,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppTheme.textPrimary),
              onPressed: () => OnboardingProvider.of(context).abort(context),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: OnboardingProvider.of(context).progress(context),
                    backgroundColor: AppTheme.dividerColor,
                    valueColor:
                        const AlwaysStoppedAnimation(AppTheme.primaryColor),
                    minHeight: 4,
                  ),
                ),
              ),

              // Body
              Expanded(child: _buildBody(l10n)),

              // Bottom button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: (_loading || _error != null || _submitting)
                        ? null
                        : (hasAnyAnswer ? _submit : _skip),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasAnyAnswer
                          ? AppTheme.primaryColor
                          : AppTheme.primaryColor.withAlpha(102),
                      foregroundColor: AppTheme.surfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            hasAnyAnswer
                                ? l10n.continueButton
                                : l10n.skipForNow,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(
        key: Key('compatibility-loading'),
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        key: const Key('compatibility-error'),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                'Could not load questions',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _load,
                child: Text(l10n.retryButton),
              ),
            ],
          ),
        ),
      );
    }

    final questions = _questions ?? [];

    // Group questions by category (preserving order of first appearance)
    final categoryOrder = <String>[];
    final grouped = <String, List<CompatibilityQuestion>>{};
    for (final q in questions) {
      if (!grouped.containsKey(q.category)) {
        categoryOrder.add(q.category);
        grouped[q.category] = [];
      }
      grouped[q.category]!.add(q);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Compatibility questions',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us find your best matches.',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          for (final category in categoryOrder) ...[
            _CategorySection(
              category: category,
              questions: grouped[category]!,
              answers: _answers,
              onSelect: _selectOption,
            ),
            const SizedBox(height: 28),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── Private widgets ────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.questions,
    required this.answers,
    required this.onSelect,
  });

  final String category;
  final List<CompatibilityQuestion> questions;
  final Map<String, String> answers;
  final void Function(String questionId, String option) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        for (final q in questions) ...[
          _QuestionTile(
            question: q,
            selectedOption: answers[q.id],
            onSelect: (opt) => onSelect(q.id, opt),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    required this.question,
    required this.selectedOption,
    required this.onSelect,
  });

  final CompatibilityQuestion question;
  final String? selectedOption;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: question.options.map((opt) {
            final isSelected = selectedOption == opt;
            return GestureDetector(
              onTap: () => onSelect(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.dividerColor,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.textOnPrimary
                        : AppTheme.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
