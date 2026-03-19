import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';

/// Interests Screen — "What are you into?"
/// Categorized chip selection, max 10 interests total
/// Optional screen that contributes to profile completeness %
class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  static const int _maxInterests = 10;

  final Set<String> _selected = {};

  // Categories with emoji header and interest options
  static const Map<String, Map<String, List<String>>> _categories = {
    '🏔️': {
      'Outdoors & adventure': [
        'Rowing', 'Diving', 'Jetskiing', 'Walking tours', 'Nature',
        'Hot Springs', 'Surfing', 'Hiking', 'Rock climbing', 'Camping',
        'Kayaking', 'Skiing', 'Mountain biking', 'Fishing', 'Sailing',
      ],
    },
    '🌍': {
      'Values & causes': [
        'Mental Health Awareness', 'Voter Rights', 'Climate Change',
        'Human Rights', 'Animal Welfare', 'Equality', 'Sustainability',
        'Volunteering', 'Education', 'Community Service',
      ],
    },
    '🏠': {
      'Staying in': [
        'Reading', 'Binge-Watching TV shows', 'Home Workout', 'Cooking',
        'Baking', 'Gardening', 'Board games', 'Video games', 'Puzzles',
        'Meditation', 'Journaling', 'Knitting', 'Painting',
      ],
    },
    '🎬': {
      'TV & movies': [
        'Action movies', 'Animated movies', 'Crime shows', 'Comedy',
        'Documentary', 'Drama', 'Horror', 'Sci-fi', 'Reality TV',
        'Thriller', 'Romance', 'Indie films', 'K-drama',
      ],
    },
    '🎵': {
      'Music': [
        'Pop', 'Rock', 'Hip-hop', 'R&B', 'Country', 'Electronic',
        'Jazz', 'Classical', 'Latin', 'K-pop', 'Metal', 'Indie',
      ],
    },
    '🍕': {
      'Food & drink': [
        'Coffee', 'Wine', 'Craft beer', 'Cocktails', 'Brunch',
        'Street food', 'Fine dining', 'Vegan', 'Sushi', 'BBQ',
        'Tacos', 'Pizza', 'Tea',
      ],
    },
    '💃': {
      'Going out': [
        'Nightlife', 'Concerts', 'Festivals', 'Theater', 'Museums',
        'Art galleries', 'Comedy shows', 'Sports events', 'Karaoke',
        'Dancing', 'Bars', 'Road trips', 'Travel',
      ],
    },
  };

  void _toggleInterest(String interest) {
    setState(() {
      if (_selected.contains(interest)) {
        _selected.remove(interest);
      } else if (_selected.length < _maxInterests) {
        _selected.add(interest);
      }
    });
  }

  void _continue() {
    OnboardingProvider.of(context).data.interests = _selected.toList();

    OnboardingProvider.of(context).goNext(context);
  }

  void _skip() {
    OnboardingProvider.of(context).data.interests = _selected.toList();

    OnboardingProvider.of(context).goNext(context);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'screen:onboarding-interests',
      child: Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _skip,
            child: Text(
              AppLocalizations.of(context).skipButton,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textPrimary),
            onPressed: () => OnboardingProvider.of(context).abort(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: OnboardingProvider.of(context).progress(context),
                      backgroundColor: AppTheme.dividerColor,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                      minHeight: 4,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context).whatAreYouInto,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context).addUpToInterests(_maxInterests),
                          style: TextStyle(
                            fontSize: 15,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context).interestsSelectedCount(_selected.length, _maxInterests),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _selected.length >= _maxInterests
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Categories
                        ..._categories.entries.map((catEntry) {
                          final emoji = catEntry.key;
                          final innerMap = catEntry.value;
                          final titleKey = innerMap.keys.first;
                          final options = innerMap.values.first;
                          final l10n = AppLocalizations.of(context);
                          final catNames = <String, String>{
                            'Outdoors & adventure': l10n.interestCategoryOutdoors,
                            'Values & causes': l10n.interestCategoryValues,
                            'Staying in': l10n.interestCategoryStayingIn,
                            'TV & movies': l10n.interestCategoryTvMovies,
                            'Music': l10n.interestCategoryMusic,
                            'Food & drink': l10n.interestCategoryFoodDrink,
                            'Going out': l10n.interestCategoryGoingOut,
                          };
                          final title = catNames[titleKey] ?? titleKey;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(emoji,
                                        style: const TextStyle(fontSize: 22)),
                                    const SizedBox(width: 8),
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: options.map((interest) {
                                    final isSelected =
                                        _selected.contains(interest);
                                    final isFull = _selected.length >=
                                            _maxInterests &&
                                        !isSelected;
                                    return GestureDetector(
                                      onTap: isFull
                                          ? null
                                          : () => _toggleInterest(interest),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppTheme.primaryColor
                                              : AppTheme.surfaceColor,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppTheme.primaryColor
                                                : isFull
                                                    ? AppTheme.dividerColor
                                                    : AppTheme.dividerColor
                                                        .withAlpha(51),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Text(
                                          interest,
                                          style: TextStyle(
                                            color: isSelected
                                                ? AppTheme.textOnPrimary
                                                : isFull
                                                    ? AppTheme.textTertiary
                                                    : AppTheme.textPrimary,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),

                // Continue button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selected.isNotEmpty
                            ? AppTheme.primaryColor
                            : AppTheme.primaryColor.withAlpha(102),
                        foregroundColor: AppTheme.surfaceColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _selected.isNotEmpty ? AppLocalizations.of(context).continueButton : AppLocalizations.of(context).skipForNow,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
