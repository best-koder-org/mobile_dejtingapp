import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shimmer animation effect for skeleton loading placeholders.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-1.0 + 2.0 * _controller.value + 1.0, 0),
              colors: const [
                Color(0xFF2A2A2E),
                Color(0xFF3A3A3E),
                Color(0xFF2A2A2E),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton for a match card in the horizontal scrolling list.
class MatchCardSkeleton extends StatelessWidget {
  const MatchCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ShimmerBox(width: 76, height: 76, borderRadius: 38),
          const SizedBox(height: 8),
          const ShimmerBox(width: 60, height: 12),
        ],
      ),
    );
  }
}

/// Skeleton for a conversation row.
class ConversationSkeleton extends StatelessWidget {
  const ConversationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const ShimmerBox(width: 56, height: 56, borderRadius: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 120, height: 14),
                const SizedBox(height: 6),
                ShimmerBox(width: 200, height: 12),
              ],
            ),
          ),
          const ShimmerBox(width: 40, height: 12),
        ],
      ),
    );
  }
}

/// Skeleton for a chat message bubble.
class MessageBubbleSkeleton extends StatelessWidget {
  final bool isMe;
  const MessageBubbleSkeleton({super.key, this.isMe = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          left: isMe ? 80 : 16,
          right: isMe ? 16 : 80,
          top: 4,
          bottom: 4,
        ),
        child: ShimmerBox(
          width: isMe ? 160 : 200,
          height: 40,
          borderRadius: 16,
        ),
      ),
    );
  }
}

/// Skeleton placeholder for the discover/profile card.
class DiscoverCardSkeleton extends StatelessWidget {
  const DiscoverCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: const ShimmerBox(width: double.infinity, height: double.infinity),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ShimmerBox(width: 140, height: 24),
              const SizedBox(width: 8),
              const ShimmerBox(width: 40, height: 24),
            ],
          ),
          const SizedBox(height: 8),
          const ShimmerBox(width: 200, height: 14),
        ],
      ),
    );
  }
}

/// Full-page skeleton for the matches screen.
class MatchesScreenSkeleton extends StatelessWidget {
  const MatchesScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Match cards row
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: List.generate(5, (_) => const MatchCardSkeleton()),
          ),
        ),
        const SizedBox(height: 16),
        // Conversations
        ...List.generate(6, (_) => const ConversationSkeleton()),
      ],
    );
  }
}

/// Full-page skeleton for the chat screen.
class ChatScreenSkeleton extends StatelessWidget {
  const ChatScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const MessageBubbleSkeleton(),
        const MessageBubbleSkeleton(isMe: true),
        const MessageBubbleSkeleton(),
        const MessageBubbleSkeleton(),
        const MessageBubbleSkeleton(isMe: true),
        const MessageBubbleSkeleton(),
      ],
    );
  }
}
