import 'package:flutter/material.dart';
import 'package:dejtingapp/l10n/generated/app_localizations.dart';
import 'package:dejtingapp/services/forum_service.dart';
import 'package:dejtingapp/widgets/forum/forum_answer_card.dart';
import 'package:dejtingapp/widgets/forum/forum_labels.dart';

/// A single topic and its answers.
///
/// The topic stays pinned at the top and every answer sits under it, oldest first, so the
/// thread reads as a conversation. Answers carry their own +1/-1 exactly like the topic does,
/// and both use the same rule: one vote per user per item, and tapping the same arrow again
/// removes the vote.
class ForumTopicScreen extends StatefulWidget {
  const ForumTopicScreen({super.key, required this.topic, this.service});

  final ForumTopic topic;

  /// Test seam, same as ForumFeedScreen: lets a widget test drive this with a stubbed client
  /// instead of the app-wide singleton.
  @visibleForTesting
  final ForumService? service;

  @override
  State<ForumTopicScreen> createState() => _ForumTopicScreenState();
}

class _ForumTopicScreenState extends State<ForumTopicScreen> {
  late final ForumService _service = widget.service ?? ForumService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  late ForumTopic _topic = widget.topic;
  List<ForumAnswer> _answers = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  String? _composeError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _service.listAnswers(_topic.id);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result.ok) {
        _answers = result.data!.items;
      } else if (result.isUnavailable) {
        _error = AppLocalizations.of(context).forumBackendUnavailable;
      } else {
        _error = AppLocalizations.of(context).forumLoadFailed;
      }
    });
  }

  /// Updates one answer in place without rebuilding the whole list.
  void _patchAnswer(int id, {required int voteScore, required int myVote}) {
    final index = _answers.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final updated = [..._answers];
    updated[index] = updated[index].copyWith(voteScore: voteScore, myVote: myVote);
    _answers = updated;
  }

  Future<void> _voteTopic(int value) async {
    // Optimistic, same as the feed: move the arrows, then reconcile with the server.
    final previousScore = _topic.voteScore;
    final previousVote = _topic.myVote;
    final nextVote = previousVote == value ? 0 : value;
    final nextScore = previousScore - previousVote + nextVote;

    setState(() => _topic = _topic.copyWith(voteScore: nextScore, myVote: nextVote));

    final result = await _service.voteTopic(_topic.id, value);
    if (!mounted) return;

    setState(() {
      _topic = result.ok
          ? _topic.copyWith(voteScore: result.data ?? nextScore, myVote: nextVote)
          : _topic.copyWith(voteScore: previousScore, myVote: previousVote);
    });

    if (!result.ok) _showError(result);
  }

  Future<void> _voteAnswer(ForumAnswer answer, int value) async {
    final previousScore = answer.voteScore;
    final previousVote = answer.myVote;
    final nextVote = previousVote == value ? 0 : value;
    final nextScore = previousScore - previousVote + nextVote;

    setState(() => _patchAnswer(answer.id, voteScore: nextScore, myVote: nextVote));

    final result = await _service.voteAnswer(answer.id, value);
    if (!mounted) return;

    setState(() {
      if (result.ok) {
        _patchAnswer(answer.id, voteScore: result.data ?? nextScore, myVote: nextVote);
      } else {
        _patchAnswer(answer.id, voteScore: previousScore, myVote: previousVote);
      }
    });

    if (!result.ok) _showError(result);
  }

  Future<void> _reportAnswer(ForumAnswer answer) async {
    final l10n = AppLocalizations.of(context);
    final result = await _service.reportAnswer(answer.id);
    if (!mounted) return;

    // Reporting is a safety action, so always confirm the outcome — never fail silently.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.ok ? l10n.forumReportSent : l10n.forumReportFailed),
    ));
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final text = _controller.text.trim();

    if (text.isEmpty) {
      setState(() => _composeError = l10n.forumTextRequired);
      return;
    }

    setState(() {
      _sending = true;
      _composeError = null;
    });

    final result = await _service.createAnswer(_topic.id, text);
    if (!mounted) return;

    if (result.ok) {
      _controller.clear();
      setState(() => _sending = false);
      await _load();
      return;
    }

    setState(() {
      _sending = false;
      _composeError = result.isRateLimited
          ? l10n.forumRateLimited
          : result.isHeldForReview
              ? l10n.forumHeldForReview
              : result.isUnavailable
                  ? l10n.forumBackendUnavailable
                  : (result.error ?? l10n.somethingWentWrong);
    });
  }

  void _showError(ForumResult<dynamic> result) {
    final l10n = AppLocalizations.of(context);
    final message = result.isRateLimited
        ? l10n.forumRateLimited
        : result.isHeldForReview
            ? l10n.forumHeldForReview
            : result.isUnavailable
                ? l10n.forumBackendUnavailable
                : (result.error ?? l10n.somethingWentWrong);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final anonColor = forumColorFromHex(_topic.colorHex);

    return Scaffold(
      appBar: AppBar(title: Text(forumChannelLabel(l10n, _topic.channel))),
      body: Column(
        children: [
          _TopicHeader(
            topic: _topic,
            anonColor: anonColor,
            onVote: _voteTopic,
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _answers.isEmpty
                        ? Center(child: Text(l10n.forumNoAnswers))
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _answers.length,
                            itemBuilder: (context, i) => ForumAnswerCard(
                              answer: _answers[i],
                              onVote: (value) => _voteAnswer(_answers[i], value),
                              onReport: () => _reportAnswer(_answers[i]),
                            ),
                          ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_composeError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _composeError!,
                        style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          maxLength: ForumService.maxTextLength,
                          maxLines: 3,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: l10n.forumAnswerHint,
                            counterText: '',
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        tooltip: l10n.forumPostButton,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The topic, pinned above the answers.
class _TopicHeader extends StatelessWidget {
  final ForumTopic topic;
  final Color anonColor;
  final Future<void> Function(int value) onVote;

  const _TopicHeader({
    required this.topic,
    required this.anonColor,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              IconButton(
                onPressed: () => onVote(1),
                icon: Icon(
                  Icons.keyboard_arrow_up,
                  color: topic.myVote == 1
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                visualDensity: VisualDensity.compact,
              ),
              Text(
                '${topic.voteScore}',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => onVote(-1),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: topic.myVote == -1
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: anonColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        topic.pseudonym,
                        style: theme.textTheme.labelSmall?.copyWith(color: anonColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  topic.text,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
