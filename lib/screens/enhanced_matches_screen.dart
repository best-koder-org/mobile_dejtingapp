import 'package:dejtingapp/l10n/generated/app_localizations.dart';
import 'package:dejtingapp/widgets/authenticated_avatar.dart';
import 'package:dejtingapp/widgets/skeleton_loaders.dart';
import 'package:flutter/material.dart';
import 'package:dejtingapp/theme/app_theme.dart';
import '../models.dart';
import '../api_services.dart';
import 'enhanced_chat_screen.dart';

/// Matches screen — simplified from the old dual-tab layout.
///
/// Now shows only matched profiles in a scrollable list.
/// Messages have been moved to the separate [MessagesScreen].
class EnhancedMatchesScreen extends StatefulWidget {
  const EnhancedMatchesScreen({super.key});

  @override
  State<EnhancedMatchesScreen> createState() => _EnhancedMatchesScreenState();
}

class _EnhancedMatchesScreenState extends State<EnhancedMatchesScreen>
    with AutomaticKeepAliveClientMixin {
  List<MatchSummary> _matches = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      final summaries = await MatchmakingApiService().getMatches();
      if (!mounted) return;
      setState(() {
        _matches = summaries
          ..sort((a, b) => b.matchedAt.compareTo(a.matchedAt));
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading matches: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Semantics(
      label: 'screen:matches',
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.favorite, color: AppTheme.primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context).matchesTitle),
              if (_matches.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_matches.length}',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: _isLoading
              ? const SingleChildScrollView(child: MatchesScreenSkeleton())
              : _buildMatchesContent(),
        ),
      ),
    );
  }

  Widget _buildMatchesContent() {
    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).noMatchesYet,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).keepSwiping,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _matches.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).newMatches,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Horizontal scroll of match avatars
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _matches.length,
                      itemBuilder: (context, i) {
                        final match = _matches[i];
                        final profile = _buildProfileFromMatch(match);
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => _openChat(profile),
                            child: Column(
                              children: [
                                AuthenticatedAvatar(profile: profile, radius: 40),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    profile.firstName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          // Match list items
          final match = _matches[index - 1];
          return _buildMatchCard(match);
        },
      ),
    );
  }

  Widget _buildMatchCard(MatchSummary match) {
    final profile = _buildProfileFromMatch(match);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: SizedBox(
          width: 48,
          height: 48,
          child: AuthenticatedAvatar(profile: profile),
        ),
        title: Text(
          profile.firstName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'New match! Say hello',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppTheme.textTertiary,
        ),
        onTap: () => _openChat(profile),
      ),
    );
  }

  UserProfile _buildProfileFromMatch(MatchSummary match) {
    return UserProfile(
      userId: match.keycloakUserId ?? match.matchedUserId,
      firstName: match.displayName.split(' ').first,
      lastName: '',
      dateOfBirth: DateTime(2000, 1, 1),
      photoUrls: match.photoUrl != null ? [match.photoUrl!] : [],
    );
  }

  void _openChat(UserProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedChatScreen(
          match: Match(
            id: '',
            userId1: '',
            userId2: profile.userId,
            matchedAt: DateTime.now(),
            otherUserProfile: profile,
          ),
        ),
      ),
    ).then((_) {
      _loadMatches();
    });
  }
}
