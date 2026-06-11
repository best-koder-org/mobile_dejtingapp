import 'package:flutter/material.dart';
import 'package:dejtingapp/models/match_insight.dart';
import 'package:dejtingapp/models.dart';
import 'package:dejtingapp/widgets/authenticated_avatar.dart';
import 'package:dejtingapp/theme/app_theme.dart';

/// A card shown in the chat screen between the safety notice and messages.
///
/// Displays "What brings you together" with both users' profile pictures,
/// a headline, evidence chips, and a suggested conversation prompt.
///
/// Matches the Samsung screenshot design: rounded container, two circular
/// avatars (current user + match), "Dance" chip, and actionable text.
class ConnectionInsightCard extends StatelessWidget {
  final ConnectionHook hook;
  final UserProfile matchProfile;
  final UserProfile? currentUserProfile;
  final TextEditingController? messageController;
  final FocusNode? messageFocusNode;

  const ConnectionInsightCard({
    super.key,
    required this.hook,
    required this.matchProfile,
    this.currentUserProfile,
    this.messageController,
    this.messageFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── Header row ───
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'What brings you together',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  // Confidence badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _confidenceColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      hook.confidenceLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _confidenceColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ─── Avatar row ───
              Row(
                children: [
                  // Current user avatar (or placeholder)
                  AuthenticatedAvatar(
                    profile: currentUserProfile,
                    radius: 22,
                  ),
                  // Overlap effect
                  Transform.translate(
                    offset: const Offset(-10, 0),
                    child: AuthenticatedAvatar(
                      profile: matchProfile,
                      radius: 22,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Headline text
                  Expanded(
                    child: Text(
                      hook.headline,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ─── Evidence chips ───
              if (hook.evidenceChips.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: hook.evidenceChips.map((chip) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      chip,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  )).toList(),
                ),
              const SizedBox(height: 10),

              // ─── Suggested prompt ───
              GestureDetector(
                onTap: () {
                  if (messageController != null) {
                    messageController!.text = hook.suggestedPrompt;
                    messageController!.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: hook.suggestedPrompt.length,
                    );
                    messageFocusNode?.requestFocus();
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.textTertiary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          hook.suggestedPrompt,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textTertiary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: AppTheme.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _confidenceColor {
    switch (hook.confidenceLabel) {
      case 'Strong signal':
        return Colors.green;
      case 'Worth exploring':
        return Colors.orange;
      case 'Different rhythms':
        return AppTheme.textTertiary;
      default:
        return AppTheme.textTertiary;
    }
  }
}
