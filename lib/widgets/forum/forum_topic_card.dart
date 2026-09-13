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

  /// Opens the topic's own page, where the answers live.
  ///
  /// Answers used to expand inline inside this card. They now belong to
  /// [ForumTopicScreen] so a thread reads as one conversation, and so answers can carry
  /// their own votes — which needs the full width of a screen.
  final VoidCallback onOpen;

  final Future<void> Function() onDelete;

  /// Reports this topic to the safety service.
  final Future<void> Function() onReport;

  const ForumTopicCard({
    super.key,
    required this.topic,
    required this.onVote,
    required this.onOpen,
    required this.onDelete,
    required this.onReport,
  });

  @override
  State<ForumTopicCard> createState() => _ForumTopicCardState();
}

class _ForumTopicCardState extends State<ForumTopicCard> {
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
                            onPressed: widget.onOpen,
                            icon: const Icon(Icons.mode_comment_outlined, size: 16),
                            label: Text('${topic.answerCount} ${l10n.forumAnswerCount}'),
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
