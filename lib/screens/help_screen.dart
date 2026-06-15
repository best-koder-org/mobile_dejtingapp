import 'package:dejtingapp/l10n/generated/app_localizations.dart';
import 'package:dejtingapp/theme/app_theme.dart';
import 'package:flutter/material.dart';

import '../services/support_service.dart';

/// Help & Support screen with a working feedback form (T091).
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  SupportCategory _category = SupportCategory.bug;
  bool _submitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final ticketId = await SupportService.submitFeedback(
        category: _category,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        contactEmail: _emailController.text.trim(),
      );
      if (!mounted) return;
      _subjectController.clear();
      _descriptionController.clear();
      _emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ticketId.isEmpty
                ? 'Thanks! Your feedback was submitted.'
                : 'Thanks! Ticket $ticketId submitted.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpScreenTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── FAQ Section ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Frequently Asked Questions',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildFaqItem(
                        'How does matching work?',
                        "You'll see profiles in your Discover feed. Swipe right to like, left to pass. "
                        "When two people like each other, it's a match! You can then start chatting.",
                      ),
                      _buildFaqItem(
                        'What are Sparks?',
                        "Sparks are special likes that include a personal message. "
                        "They're more noticeable than regular likes and triple your chance of matching. "
                        "You can buy Sparks in the Sparks Store.",
                      ),
                      _buildFaqItem(
                        'How do I verify my profile?',
                        'Go to Settings → Verify Account and take a selfie. '
                        'Our system will check it against your profile photos. '
                        'Verified profiles get more matches!',
                      ),
                      _buildFaqItem(
                        'How do I block someone?',
                        'Go to their profile or chat, tap the menu (⋮), and select Block. '
                        'You can also manage blocked users in Settings → Privacy & Security.',
                      ),
                      _buildFaqItem(
                        'How do I pause or delete my account?',
                        'To take a break, use the Pause feature in Settings. '
                        'To permanently delete your account, contact us through the feedback form below.',
                      ),
                      _buildFaqItem(
                        'What does Premium include?',
                        'Premium gives you: see who liked you, compatibility deep-dives, '
                        'advanced filters, unlimited Sparks, and more. Check the Sparks Store for plans.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Row(
                children: [
                  Icon(Icons.support_agent,
                      color: AppTheme.primaryColor, size: 28),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Need help or found a problem? Tell us below.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<SupportCategory>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: SupportCategory.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.label),
                        ))
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (v) => setState(
                        () => _category = v ?? SupportCategory.bug),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                enabled: !_submitting,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a subject'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                enabled: !_submitting,
                maxLength: 4000,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please describe the issue'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                enabled: !_submitting,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Contact email (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_submitting ? 'Sending...' : 'Submit feedback'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(answer,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ),
      ],
    );
  }
}
