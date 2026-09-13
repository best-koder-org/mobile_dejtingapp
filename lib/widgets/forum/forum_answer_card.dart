import 'package:flutter/material.dart';
import 'package:dejtingapp/l10n/generated/app_localizations.dart';
import 'package:dejtingapp/services/forum_service.dart';
import 'package:dejtingapp/widgets/forum/forum_labels.dart';

/// One answer in a topic's sub-page.
///
/// Vote state is deliberately NOT held here: the parent owns the answer list and patches the
/// answer after a vote, so there is a single source of truth (same rule as the topic card).
class ForumAnswerCard extends StatelessWidget {
  final ForumAnswer answer;

  /// Casts or toggles a vote on this answer.
  final Future<void> Function(int value) onVote;

  /// Reports this answer to the safety service.
  final Future<void> Function() onReport;

  const ForumAnswerCard({
    super.key,
    required this.answer,
    required this.onVote,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final anonColor = forumColorFromHex(answer.colorHex);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vote column, mirroring the topic card so the gesture is the same everywhere.
          Column(
            children: [
              _VoteButton(
                icon: Icons.keyboard_arrow_up,
                active: answer.myVote == 1,
                onTap: () => onVote(1),
              ),
              Text(
                '${answer.voteScore}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: answer.myVote != 0
                      ? anonColor
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              _VoteButton(
                icon: Icons.keyboard_arrow_down,
                active: answer.myVote == -1,
                onTap: () => onVote(-1),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            // Each answer gets its own tinted bubble, matching the feed cards (and Jodel's
            // thread view) so the anonymous colour is consistent in both places.
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  anonColor.withValues(alpha: 0.14),
                  theme.colorScheme.surface,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
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
                        answer.pseudonym,
                        style: theme.textTheme.labelSmall?.copyWith(color: anonColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: onReport,
                      icon: const Icon(Icons.flag_outlined, size: 16),
                      visualDensity: VisualDensity.compact,
                      tooltip: AppLocalizations.of(context).forumReport,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(answer.text, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _VoteButton({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          icon,
          size: 20,
          color: active
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
