import 'package:flutter/material.dart';
import 'package:dejtingapp/theme/app_theme.dart';
import 'package:dejtingapp/services/forum_service.dart';

/// Community forum feed — Tab 5 in main nav.
/// Shows hot-sorted posts with upvote/downvote, category filter, and compose.
class ForumFeedScreen extends StatefulWidget {
  const ForumFeedScreen({super.key});

  @override
  State<ForumFeedScreen> createState() => _ForumFeedScreenState();
}

class _ForumFeedScreenState extends State<ForumFeedScreen>
    with AutomaticKeepAliveClientMixin {
  final ForumService _service = ForumService();

  List<ForumPost> _posts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _selectedCategory;

  static const _categories = [
    (key: null, label: 'All'),
    (key: 'general', label: 'General'),
    (key: 'dating-advice', label: 'Advice'),
    (key: 'success-stories', label: 'Success'),
    (key: 'rant', label: 'Rant'),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final posts = await _service.listPosts(category: _selectedCategory);
    if (!mounted) return;
    setState(() {
      _posts = posts;
      _isLoading = false;
    });
  }

  Future<void> _vote(int index, int value) async {
    final post = _posts[index];
    final newScore = await _service.vote(post.id, value);
    if (!mounted || newScore == null) return;
    setState(() {
      _posts[index] = post.copyWith(voteScore: newScore);
    });
  }

  Future<void> _showCompose() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ComposeSheet(service: _service),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        title: const Text(
          'Community',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: _CategoryChips(
            selected: _selectedCategory,
            categories: _categories,
            onSelected: (key) {
              setState(() => _selectedCategory = key);
              _load();
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCompose,
        backgroundColor: AppTheme.primaryColor,
        tooltip: 'New post',
        child: const Icon(Icons.edit_outlined, color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.textSecondary, size: 48),
            const SizedBox(height: 12),
            const Text('Could not load posts', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined, color: AppTheme.textSecondary, size: 64),
            const SizedBox(height: 16),
            const Text(
              'No posts yet — be the first!',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showCompose,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Write something'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _posts.length,
        separatorBuilder: (_, __) =>
            const Divider(color: AppTheme.dividerColor, height: 1),
        itemBuilder: (context, i) => _PostCard(
          post: _posts[i],
          onUpvote: () => _vote(i, 1),
          onDownvote: () => _vote(i, -1),
        ),
      ),
    );
  }
}

// ─── Category chips ────────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  final String? selected;
  final List<({String? key, String label})> categories;
  final void Function(String?) onSelected;

  const _CategoryChips({
    required this.selected,
    required this.categories,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = cat.key == selected;
          return GestureDetector(
            onTap: () => onSelected(cat.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
                ),
              ),
              child: Text(
                cat.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Post card ────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final ForumPost post;
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;

  const _PostCard({
    required this.post,
    required this.onUpvote,
    required this.onDownvote,
  });

  static String _formatAge(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vote column
          _VoteColumn(score: post.voteScore, onUp: onUpvote, onDown: onDownvote),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    post.category,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  post.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  post.body,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatAge(post.createdAt),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteColumn extends StatelessWidget {
  final int score;
  final VoidCallback onUp;
  final VoidCallback onDown;

  const _VoteColumn({
    required this.score,
    required this.onUp,
    required this.onDown,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onUp,
          child: const Icon(Icons.keyboard_arrow_up, color: AppTheme.textSecondary, size: 28),
        ),
        Text(
          '$score',
          style: TextStyle(
            color: score > 0
                ? AppTheme.primaryColor
                : score < 0
                    ? Colors.redAccent
                    : AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: onDown,
          child: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary, size: 28),
        ),
      ],
    );
  }
}

// ─── Compose bottom sheet ──────────────────────────────────────────────────────

class _ComposeSheet extends StatefulWidget {
  final ForumService service;

  const _ComposeSheet({required this.service});

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _category = 'general';
  bool _submitting = false;
  String? _error;

  static const _cats = ['general', 'dating-advice', 'success-stories', 'rant'];

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      setState(() => _error = 'Title and body are required.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final id = await widget.service.createPost(
      title: title,
      body: body,
      category: _category,
    );
    if (!mounted) return;
    if (id != null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _submitting = false;
        _error = 'Failed to post. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'New Post',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          // Category picker
          DropdownButtonFormField<String>(
            value: _category,
            dropdownColor: AppTheme.surfaceElevated,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Category',
              labelStyle: const TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.dividerColor),
              ),
            ),
            items: _cats
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? 'general'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            maxLength: 200,
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle: const TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.dividerColor),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            maxLines: 4,
            maxLength: 5000,
            decoration: InputDecoration(
              labelText: 'What\'s on your mind?',
              labelStyle: const TextStyle(color: AppTheme.textSecondary),
              alignLabelWithHint: true,
              filled: true,
              fillColor: AppTheme.surfaceColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.dividerColor),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
