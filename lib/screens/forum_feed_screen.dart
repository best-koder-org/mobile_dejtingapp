import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:dejtingapp/backend_url.dart';
import 'package:dejtingapp/services/api_service.dart';
import 'package:dejtingapp/theme/app_theme.dart';

/// Jodel-inspired simple forum — one main feed, posts + comments.
/// Anonymous posting option, no subforums.
class ForumFeedScreen extends StatefulWidget {
  const ForumFeedScreen({super.key});

  @override
  State<ForumFeedScreen> createState() => _ForumFeedScreenState();
}

class _ForumFeedScreenState extends State<ForumFeedScreen> {
  List<_ForumPost> _posts = [];
  bool _loading = true;
  bool _isAnonymous = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    try {
      final token = await AppState().getOrRefreshAuthToken();
      final url = Uri.parse('${ApiUrls.matchmakingService}/api/forum/posts');
      final resp = await http.get(url, headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (resp.statusCode == 200 && mounted) {
        final list = jsonDecode(resp.body) as List;
        setState(() {
          _posts = list.map((j) => _ForumPost.fromJson(j)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createPost(String content) async {
    if (content.trim().isEmpty) return;
    try {
      final token = await AppState().getOrRefreshAuthToken();
      final url = Uri.parse('${ApiUrls.matchmakingService}/api/forum/posts');
      final resp = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'content': content, 'isAnonymous': _isAnonymous}));
      if (resp.statusCode == 200) {
        _loadPosts();
      }
    } catch (_) {}
  }

  Future<void> _createComment(int postId, String content) async {
    if (content.trim().isEmpty) return;
    try {
      final token = await AppState().getOrRefreshAuthToken();
      final url = Uri.parse('${ApiUrls.matchmakingService}/api/forum/posts/$postId/comments');
      await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'content': content}));
      _loadPosts();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Forum', style: TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isAnonymous ? Icons.visibility_off : Icons.visibility,
                color: _isAnonymous ? AppTheme.primaryColor : Colors.grey),
            tooltip: _isAnonymous ? 'Anonymt inlägg' : 'Visar ditt namn',
            onPressed: () => setState(() => _isAnonymous = !_isAnonymous),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPosts,
              child: _posts.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text('Inga inlägg än.\nVar först med att posta!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF8B8578), fontSize: 16)),
                      ),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _posts.length,
                      itemBuilder: (ctx, i) => _PostCard(
                        post: _posts[i],
                        onComment: (content) => _createComment(_posts[i].id, content),
                      ),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePostDialog(),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('Skapa inlägg', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showCreatePostDialog() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nytt inlägg',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLength: 1000,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Vad tänker du på?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Switch(
                  value: _isAnonymous,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (v) => setState(() => _isAnonymous = v),
                ),
                Text(_isAnonymous ? 'Anonym' : 'Med namn',
                    style: const TextStyle(fontSize: 13)),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    _createPost(controller.text);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: const Text('Posta', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Models ────────────────────────────────────────────────────────

class _ForumPost {
  final int id;
  final String content;
  final bool isAnonymous;
  final String authorName;
  final DateTime createdAt;
  int commentCount;
  List<_ForumComment>? comments;

  _ForumPost({
    required this.id,
    required this.content,
    required this.isAnonymous,
    required this.authorName,
    required this.createdAt,
    required this.commentCount,
  });

  factory _ForumPost.fromJson(Map<String, dynamic> j) => _ForumPost(
    id: j['id'] as int,
    content: j['content'] as String? ?? '',
    isAnonymous: j['isAnonymous'] as bool? ?? false,
    authorName: (j['isAnonymous'] as bool? ?? false) ? 'Anonym' : 'Användare',
    createdAt: DateTime.parse(j['createdAt'] as String),
    commentCount: j['commentCount'] as int? ?? 0,
  );
}

class _ForumComment {
  final int id;
  final String content;
  final String authorName;
  final DateTime createdAt;

  _ForumComment({required this.id, required this.content, required this.authorName, required this.createdAt});
  factory _ForumComment.fromJson(Map<String, dynamic> j) => _ForumComment(
    id: j['id'] as int,
    content: j['content'] as String? ?? '',
    authorName: 'Användare',
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

// ── Widgets ───────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final _ForumPost post;
  final Future<void> Function(String) onComment;

  const _PostCard({required this.post, required this.onComment});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _expanded = false;
  bool _loadingComments = false;

  Future<void> _loadComments() async {
    setState(() => _loadingComments = true);
    try {
      final token = await AppState().getOrRefreshAuthToken();
      final url = Uri.parse('${ApiUrls.userService}/api/forum/posts/${widget.post.id}/comments');
      final resp = await http.get(url, headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (resp.statusCode == 200 && mounted) {
        final list = jsonDecode(resp.body) as List;
        setState(() {
          widget.post.comments = list.map((j) => _ForumComment.fromJson(j)).toList();
          _loadingComments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  void _toggleComments() {
    final wasExpanded = _expanded;
    setState(() => _expanded = !_expanded);
    if (!wasExpanded && widget.post.comments == null) {
      _loadComments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final timeAgo = _formatTimeAgo(p.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: author + time
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                  child: const Icon(Icons.person, size: 16, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 8),
                Text(p.authorName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const Spacer(),
                Text(timeAgo, style: const TextStyle(color: Color(0xFF8B8578), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            // Content
            Text(p.content, style: const TextStyle(fontSize: 15, height: 1.4)),
            const SizedBox(height: 10),
            // Actions: comment button
            Row(
              children: [
                GestureDetector(
                  onTap: _toggleComments,
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 18, color: _expanded ? AppTheme.primaryColor : Colors.grey),
                      const SizedBox(width: 4),
                      Text('${p.commentCount}', style: TextStyle(fontSize: 13, color: _expanded ? AppTheme.primaryColor : Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            // Comments section
            if (_expanded) ...[
              const Divider(height: 20),
              if (_loadingComments)
                const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              else ...[
                ...?p.comments?.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('└ ', style: TextStyle(color: Color(0xFF8B8578), fontSize: 13)),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Color(0xFF2D2D2D), fontSize: 14),
                            children: [
                              TextSpan(
                                text: '${c.authorName}: ',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              TextSpan(text: c.content),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                // Add comment input
                _CommentInput(onSubmit: (text) => widget.onComment(text)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Nu';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('d MMM').format(dt);
  }
}

class _CommentInput extends StatefulWidget {
  final Future<void> Function(String) onSubmit;
  const _CommentInput({required this.onSubmit});

  @override
  State<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<_CommentInput> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              hintText: 'Skriv en kommentar...',
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        _sending
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : IconButton(
                icon: const Icon(Icons.send, color: AppTheme.primaryColor, size: 20),
                onPressed: () async {
                  if (_ctrl.text.trim().isEmpty) return;
                  setState(() => _sending = true);
                  await widget.onSubmit(_ctrl.text);
                  _ctrl.clear();
                  if (mounted) setState(() => _sending = false);
                },
              ),
      ],
    );
  }
}
