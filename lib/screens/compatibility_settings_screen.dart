import 'package:flutter/material.dart';

import '../services/compatibility_service.dart';
import '../theme/app_theme.dart';

/// T517 — Standalone compatibility questions screen accessible from
/// Profile Hub / Settings. Lets users re-answer (or answer for the first
/// time) the compatibility questions outside of onboarding.
///
/// Shows same question list as [CompatibilityQuestionsScreen] but with
/// a "Done" button instead of an onboarding-flow next step.
class CompatibilitySettingsScreen extends StatefulWidget {
  /// Optional injectable service for testing.
  final CompatibilityService service;

  const CompatibilitySettingsScreen({
    super.key,
    this.service = const DefaultCompatibilityService(),
  });

  @override
  State<CompatibilitySettingsScreen> createState() =>
      _CompatibilitySettingsScreenState();
}

class _CompatibilitySettingsScreenState
    extends State<CompatibilitySettingsScreen> {
  List<CompatibilityQuestion>? _questions;
  bool _loading = true;
  String? _error;
  bool _submitting = false;

  /// questionId → chosen option
  final Map<String, String> _answers = {};

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

  void _selectOption(String questionId, String option) {
    setState(() => _answers[questionId] = option);
  }

  Future<void> _save() async {
    if (_answers.isEmpty) {
      Navigator.pop(context);
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.service.submitAnswers(Map<String, String>.from(_answers));
      if (mounted) {
        setState(() {
          _submitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dina svar har sparats!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kunde inte spara: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        title: const Text(
          'Kompatibilitetsfrågor',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody()),
            if (!_loading && _error == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _answers.isNotEmpty
                          ? AppTheme.primaryColor
                          : AppTheme.primaryColor.withValues(alpha: 0.4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26)),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _answers.isNotEmpty ? 'Spara svar' : 'Avsluta',
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        key: Key('compat-settings-loading'),
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('compat-settings-retry'),
                onPressed: _load,
                child: const Text('Försök igen'),
              ),
            ],
          ),
        ),
      );
    }

    final questions = _questions ?? [];
    if (questions.isEmpty) {
      return const Center(
        child: Text('Inga frågor tillgängliga.',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    // Group by category
    final Map<String, List<CompatibilityQuestion>> grouped = {};
    for (final q in questions) {
      grouped.putIfAbsent(q.category, () => []).add(q);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        const Text(
          'Svara på frågor för att förbättra dina matchningar. '
          'Du kan ändra dina svar när som helst.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        ...grouped.entries.map((entry) => _buildCategory(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildCategory(String category, List<CompatibilityQuestion> questions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Text(
            category,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...questions.map((q) => _buildQuestionCard(q)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildQuestionCard(CompatibilityQuestion q) {
    final selected = _answers[q.id];
    return Card(
      color: AppTheme.surfaceElevated,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              q.text,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: q.options.map((opt) {
                final isSelected = selected == opt;
                return ChoiceChip(
                  label: Text(opt),
                  selected: isSelected,
                  onSelected: (_) => _selectOption(q.id, opt),
                  selectedColor: AppTheme.primaryColor,
                  backgroundColor: AppTheme.surfaceColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
