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

  /// Begins recording. Null hides the microphone entirely — web builds cannot record.
  final Future<void> Function()? onStartDictation;

  /// Stops recording and transcribes, returning the text to drop into the field. A null
  /// result means the caller already explained the failure with a snackbar.
  final Future<String?> Function()? onStopDictation;

  const ForumComposeSheet({
    super.key,
    required this.onSubmit,
    this.onStartDictation,
    this.onStopDictation,
  });

  bool get supportsDictation => onStartDictation != null && onStopDictation != null;

  @override
  State<ForumComposeSheet> createState() => _ForumComposeSheetState();
}

class _ForumComposeSheetState extends State<ForumComposeSheet> {
  final TextEditingController _controller = TextEditingController();
  String _channel = 'vent';
  String? _error;
  bool _sending = false;
  bool _dictating = false;
  bool _recording = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Toggles the microphone: first tap records, second tap stops and transcribes.
  Future<void> _toggleDictation() async {
    if (_dictating) return;

    if (!_recording) {
      setState(() {
        _recording = true;
        _error = null;
      });
      await widget.onStartDictation!();
      return;
    }

    setState(() {
      _recording = false;
      _dictating = true;
    });

    final text = await widget.onStopDictation!();
    if (!mounted) return;

    // A null result means the caller already explained why, so do not overwrite its message.
    if (text == null || text.trim().isEmpty) {
      setState(() => _dictating = false);
      return;
    }

    setState(() {
      _dictating = false;
      _controller.text = text.trim();
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
    });
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
              hintText: _recording ? l10n.forumRecording : l10n.forumComposeHint,
              border: const OutlineInputBorder(),
              errorText: _error,
              suffixIcon: !widget.supportsDictation
                  ? null
                  : IconButton(
                      tooltip: _recording ? l10n.forumRecording : l10n.forumDictate,
                      onPressed: _dictating || _sending ? null : _toggleDictation,
                      icon: _dictating
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _recording ? Icons.stop_circle : Icons.mic_none,
                              color: _recording ? Colors.red : null,
                            ),
                    ),
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
