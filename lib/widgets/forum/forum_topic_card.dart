import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dejtingapp/l10n/generated/app_localizations.dart';
import 'package:dejtingapp/services/forum_service.dart';
import 'package:dejtingapp/widgets/forum/forum_labels.dart';

/// One topic in the feed.
///
/// Vote state is deliberately NOT held locally: the parent owns the topic list and patches
/// the topic after a vote, so there is a single source of truth. Answer state is local
/// because it is only view state for this card.
class ForumTopicCard extends StatefulWidget {
  final ForumTopic topic;

  /// Casts or toggles a vote. The parent owns the topic list and resolves the new score,
  /// so this returns nothing the card needs.
  final Future<void> Function(int value) onVote;

  /// Loads one page of answers.
  final Future<ForumResult<ForumPage<ForumAnswer>>> Function(int page) onLoadAnswers;

  /// Posts an answer.
  final Future<ForumResult<int>> Function(String text) onAnswer;

  final Future<void> Function() onDelete;

  /// Reports this topic to the safety service.
  final Future<void> Function() onReport;

  const ForumTopicCard({
    super.key,
    required this.topic,
    required this.onVote,
    required this.onLoadAnswers,
    required this.onAnswer,
    required this.onDelete,
    required this.onReport,
  });

  @override
  State<ForumTopicCard> createState() => _ForumTopicCardState();
}

class _ForumTopicCardState extends State<ForumTopicCard> {
  final TextEditingController _answerController = TextEditingController();

  List<ForumAnswer>? _answers;
  bool _expanded = false;
  bool _loading = false;
  bool _sendingAnswer = false;
  String? _answerError;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  int get _answerCount => _answers?.length ?? widget.topic.answerCount;

  Future<void> _toggle() async {
    setState(() => _expanded = !_expanded);
    if (_expanded && _answers == null) await _loadAnswers();
  }

  Future<void> _loadAnswers() async {
    setState(() => _loading = true);
    final result = await widget.onLoadAnswers(1);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.ok) {
        _answers = result.data!.items;
        _answerError = null;
      } else {
        _answerError = AppLocalizations.of(context).forumLoadFailed;
      }
    });
  }

  Future<void> _sendAnswer() async {
    final l10n = AppLocalizations.of(context);
    final text = _answerController.text.trim();

    if (text.isEmpty) {
      setState(() => _answerError = l10n.forumTextRequired);
      return;
    }

    setState(() {
      _sendingAnswer = true;
      _answerError = null;
    });

    final result = await widget.onAnswer(text);
    if (!mounted) return;

    if (result.ok) {
      _answerController.clear();
      setState(() => _sendingAnswer = false);
      await _loadAnswers();
      return;
    }

    setState(() {
      _sendingAnswer = false;
      _answerError = result.isRateLimited
          ? l10n.forumRateLimited
          : result.isHeldForReview
              ? l10n.forumHeldForReview
              : (result.error ?? l10n.somethingWentWrong);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final topic = widget.topic;
    final anonColor = forumColorFromHex(topic.colorHex);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VoteColumn(
                score: topic.voteScore,
                myVote: topic.myVote,
                onVote: widget.onVote,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: anonColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              topic.pseudonym,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: anonColor, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            forumChannelLabel(l10n, topic.channel),
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(topic.text, style: const TextStyle(fontSize: 15, height: 1.3)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: _toggle,
                            icon: Icon(
                              _expanded ? Icons.expand_less : Icons.mode_comment_outlined,
                              size: 16,
                            ),
                            label: Text('$_answerCount ${l10n.forumAnswerCount}'),
                          ),
                          const Spacer(),
                          if (topic.isOwn)
                            IconButton(
                              tooltip: 'Delete',
                              iconSize: 18,
                              visualDensity: VisualDensity.compact,
                              onPressed: () => unawaited(widget.onDelete()),
                              icon: const Icon(Icons.delete_outline),
                            )
                          else
                            IconButton(
                              tooltip: l10n.forumReport,
                              iconSize: 18,
                              visualDensity: VisualDensity.compact,
                              onPressed: () => unawaited(widget.onReport()),
                              icon: const Icon(Icons.flag_outlined),
                            ),
                          Text(
                            l10n.forumExpiresInHours(topic.hoursRemaining),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_expanded) _buildAnswers(l10n),
        ],
      ),
    );
  }

  Widget _buildAnswers(AppLocalizations l10n) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final answers = _answers ?? const <ForumAnswer>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (answers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.forumAnswerHint,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            )
          else
            ...answers.map((answer) => _AnswerTile(answer: answer)),
          const SizedBox(height: 4),
          TextField(
            controller: _answerController,
            maxLength: ForumService.maxTextLength,
            maxLines: 2,
            minLines: 1,
            decoration: InputDecoration(
              hintText: l10n.forumAnswerHint,
              isDense: true,
              border: const OutlineInputBorder(),
              errorText: _answerError,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _sendingAnswer ? null : _sendAnswer,
              child: _sendingAnswer
                  ? const SizedBox(
                      height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.forumAnswerButton),
            ),
          ),
        ],
      ),
    );
  }
}

/// Up / score / down. Sending the value you already chose removes the vote.
class _VoteColumn extends StatelessWidget {
  final int score;
  final int myVote;
  final Future<void> Function(int value) onVote;

  const _VoteColumn({required this.score, required this.myVote, required this.onVote});

  @override
  Widget build(BuildContext context) {
    final up = myVote == 1;
    final down = myVote == -1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 0, 6),
      child: Column(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 22,
            tooltip: 'Upvote',
            onPressed: () => unawaited(onVote(1)),
            icon: Icon(Icons.arrow_drop_up, color: up ? Colors.deepOrange : Colors.grey),
          ),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: up
                  ? Colors.deepOrange
                  : down
                      ? Colors.blueGrey
                      : null,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 22,
            tooltip: 'Downvote',
            onPressed: () => unawaited(onVote(-1)),
            icon: Icon(Icons.arrow_drop_down, color: down ? Colors.blueGrey : Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  final ForumAnswer answer;

  const _AnswerTile({required this.answer});

  @override
  Widget build(BuildContext context) {
    final color = forumColorFromHex(answer.colorHex);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4, right: 8),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  answer.pseudonym,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                Text(answer.text, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
