import 'package:flutter/material.dart';
import 'package:dejtingapp/l10n/generated/app_localizations.dart';
import 'package:dejtingapp/services/forum_service.dart';
import 'package:dejtingapp/widgets/forum/forum_compose_sheet.dart';
import 'package:dejtingapp/widgets/forum/forum_labels.dart';
import 'package:dejtingapp/widgets/forum/forum_topic_card.dart';

/// Jodel-style anonymous community feed.
///
/// One flat feed of short topics, each with short answers underneath. Everything is
/// anonymous: the server returns a per-topic colour and pseudonym instead of an identity,
/// so the same person keeps one colour inside a topic but is unlinkable across topics.
///
/// Topics expire after 48h, which is why each card shows roughly how long it has left.
class ForumFeedScreen extends StatefulWidget {
  const ForumFeedScreen({super.key});

  @override
  State<ForumFeedScreen> createState() => _ForumFeedScreenState();
}

class _ForumFeedScreenState extends State<ForumFeedScreen> {
  final ForumService _service = ForumService();
  final ScrollController _scroll = ScrollController();

  List<ForumTopic> _topics = [];

  /// null means every channel.
  String? _channel;

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 320) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _service.listTopics(channel: _channel, page: 1);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result.ok) {
        _topics = result.data!.items;
        _page = result.data!.page;
        _hasMore = result.data!.hasMore;
      } else {
        _error = AppLocalizations.of(context).forumLoadFailed;
      }
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    final result = await _service.listTopics(channel: _channel, page: _page + 1);
    if (!mounted) return;

    setState(() {
      _loadingMore = false;
      if (result.ok) {
        _topics = [..._topics, ...result.data!.items];
        _page = result.data!.page;
        _hasMore = result.data!.hasMore;
      }
    });
  }

  Future<void> _selectChannel(String? channel) async {
    if (_channel == channel) return;
    setState(() => _channel = channel);
    await _load();
  }

  /// Updates one topic in place without rebuilding the whole list.
  void _patch(int id, {int? voteScore, int? myVote}) {
    final index = _topics.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final updated = [..._topics];
    updated[index] = updated[index].copyWith(voteScore: voteScore, myVote: myVote);
    _topics = updated;
  }

  Future<void> _vote(ForumTopic topic, int value) async {
    // Optimistic: move the arrows straight away, then reconcile with the server's score.
    final previousScore = topic.voteScore;
    final previousVote = topic.myVote;
    final nextVote = previousVote == value ? 0 : value;
    final nextScore = previousScore - previousVote + nextVote;

    setState(() => _patch(topic.id, voteScore: nextScore, myVote: nextVote));

    final result = await _service.voteTopic(topic.id, value);
    if (!mounted) return;

    setState(() {
      if (result.ok) {
        _patch(topic.id, voteScore: result.data, myVote: nextVote);
      } else {
        _patch(topic.id, voteScore: previousScore, myVote: previousVote);
      }
    });

    if (!result.ok) _showError(result);
  }

  Future<void> _deleteTopic(ForumTopic topic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text('Delete this topic?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await _service.deleteTopic(topic.id);
    if (!mounted) return;

    if (result.ok) {
      setState(() => _topics = _topics.where((t) => t.id != topic.id).toList());
    } else {
      _showError(result);
    }
  }

  /// Creates a topic. Returns the result so the compose sheet can stay open and explain
  /// a refusal (cooldown, daily cap, held for review) instead of losing the text.
  Future<ForumResult<int>> _createTopic(String text, String channel) async {
    final result = await _service.createTopic(text: text, channel: channel);
    if (result.ok && mounted) await _load();
    return result;
  }

  void _showError(ForumResult<dynamic> result) {
    final l10n = AppLocalizations.of(context);
    final message = result.isRateLimited
        ? l10n.forumRateLimited
        : result.isHeldForReview
            ? l10n.forumHeldForReview
            : result.isUnavailable
                ? l10n.forumVoiceUnavailable
                : (result.error ?? l10n.somethingWentWrong);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openCompose() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ForumComposeSheet(onSubmit: _createTopic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.forumTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 4, bottom: 8),
                  child: ChoiceChip(
                    label: Text(l10n.forumAllChannels),
                    selected: _channel == null,
                    onSelected: (_) => _selectChannel(null),
                  ),
                ),
                ...ForumService.channels.map((slug) => Padding(
                      padding: const EdgeInsets.only(right: 8, top: 4, bottom: 8),
                      child: ChoiceChip(
                        label: Text(forumChannelLabel(l10n, slug)),
                        selected: _channel == slug,
                        onSelected: (_) => _selectChannel(slug),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody(l10n)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCompose,
        icon: const Icon(Icons.edit),
        label: Text(l10n.forumNewTopic),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return ListView(children: [
        const SizedBox(height: 120),
        Center(child: Text(_error!)),
        const SizedBox(height: 12),
        Center(
          child: TextButton(onPressed: _load, child: Text(l10n.retryButton)),
        ),
      ]);
    }

    if (_topics.isEmpty) {
      // A ListView (not a Center) so pull-to-refresh still works on an empty feed.
      return ListView(children: [
        const SizedBox(height: 120),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              l10n.forumEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ),
      ]);
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      itemCount: _topics.length + (_loadingMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i >= _topics.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final topic = _topics[i];
        return ForumTopicCard(
          key: ValueKey(topic.id),
          topic: topic,
          onVote: (value) => _vote(topic, value),
          onLoadAnswers: (page) => _service.listAnswers(topic.id, page: page),
          onAnswer: (text) => _service.createAnswer(topic.id, text),
          onDelete: () => _deleteTopic(topic),
        );
      },
    );
  }
}
