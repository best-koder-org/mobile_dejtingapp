import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final int age;
  final String bio;
  final List<String> photoUrls;
  final int? matchScore;
  final VoidCallback? onLike;
  final VoidCallback? onPass;

  const ProfileCard({
    super.key,
    required this.name,
    required this.age,
    required this.bio,
    required this.photoUrls,
    this.matchScore,
    this.onLike,
    this.onPass,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Photo Background
            _buildPhotoBackground(),
            
            // Gradient Overlay
            _buildGradientOverlay(),
            
            // Content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildContent(context),
            ),
            
            // Match Score Badge
            if (matchScore != null) _buildMatchScoreBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoBackground() {
    return AspectRatio(
      aspectRatio: 0.75,
      child: photoUrls.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: photoUrls.first,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.person, size: 80, color: Colors.grey),
              ),
            )
          : Container(
              color: Colors.grey[300],
              child: const Icon(Icons.person, size: 80, color: Colors.grey),
            ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.3),
              Colors.black.withValues(alpha: 0.8),
            ],
            stops: const [0.5, 0.75, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name and Age
          Row(
            children: [
              Expanded(
                child: Text(
                  '$name, $age',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Bio
          Text(
            bio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.95),
              height: 1.4,
              shadows: const [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 2,
                  color: Colors.black45,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pass Button
        _buildActionButton(
          icon: Icons.close,
          color: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          onTap: onPass,
        ),
        
        const SizedBox(width: 20),
        
        // Like Button
        _buildActionButton(
          icon: Icons.favorite,
          color: Colors.white,
          backgroundColor: const Color(0xFFFF6B6B),
          onTap: onLike,
          size: 64,
        ),
        
        const SizedBox(width: 20),
        
        // Super Like Button
        _buildActionButton(
          icon: Icons.star,
          color: Colors.white,
          backgroundColor: const Color(0xFF4ECDC4),
          onTap: () {}, // TODO: Implement super like
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    VoidCallback? onTap,
    double size = 56,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: size * 0.5,
        ),
      ),
    );
  }

  Widget _buildMatchScoreBadge() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6B46C1),
              const Color(0xFF9333EA),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9333EA).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.whatshot,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '$matchScore%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
