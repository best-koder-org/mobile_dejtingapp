import 'package:flutter/material.dart';
import 'package:dejtingapp/l10n/generated/app_localizations.dart';
import 'package:dejtingapp/services/forum_service.dart';
import 'package:dejtingapp/widgets/forum/forum_labels.dart';

/// Bottom sheet for starting a topic.
///
/// A topic is one short text plus a channel — there is deliberately no title, so the only
/// input is a single capped field. The sheet stays open and shows the server's reason when
/// a post is refused (cooldown, daily cap, or held for review), so the text is not lost.
class ForumComposeSheet extends StatefulWidget {
  /// Creates the topic. Return a failure to keep the sheet open and show why.
  final Future<ForumResult<int>> Function(String text, String channel) onSubmit;

  const ForumComposeSheet({super.key, required this.onSubmit});

  @override
  State<ForumComposeSheet> createState() => _ForumComposeSheetState();
}

class _ForumComposeSheetState extends State<ForumComposeSheet> {
  final TextEditingController _controller = TextEditingController();
  String _channel = 'vent';
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final text = _controller.text.trim();

    if (text.isEmpty) {
      setState(() => _error = l10n.forumTextRequired);
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    final result = await widget.onSubmit(text, _channel);
    if (!mounted) return;

    if (result.ok) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _sending = false;
      _error = result.isRateLimited
          ? l10n.forumRateLimited
          : result.isHeldForReview
              ? l10n.forumHeldForReview
              : (result.error ?? l10n.somethingWentWrong);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.forumNewTopic,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: ForumService.maxTextLength,
            maxLines: 4,
            minLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: l10n.forumComposeHint,
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
          ),
          Text(l10n.forumChannelLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: ForumService.channels.map((slug) {
              return ChoiceChip(
                label: Text(forumChannelLabel(l10n, slug)),
                selected: _channel == slug,
                onSelected: (_) => setState(() => _channel = slug),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _sending ? null : _submit,
            child: _sending
                ? const SizedBox(
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.forumPostButton),
          ),
        ],
      ),
    );
  }
}
