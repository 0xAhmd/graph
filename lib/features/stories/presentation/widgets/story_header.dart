import 'package:flutter/material.dart';
import 'package:ig_mate/features/stories/domain/entities/story.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StoryHeader extends StatelessWidget {
  final StoryEntity story;
  final VoidCallback onMorePressed;
  final VoidCallback onClosePressed;
  final String? currentUserId; // Add current user ID
  final void Function()? onTap;

  const StoryHeader({
    super.key,
    required this.onTap,
    required this.story,
    required this.onMorePressed,
    required this.onClosePressed,
    this.currentUserId, // Make it optional with default null
  });

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }


  bool _isCurrentUserStory() {
    return currentUserId != null && currentUserId == story.userId;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          // Profile picture
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey,
            backgroundImage: story.userProfileImageUrl != null
                ? CachedNetworkImageProvider(story.userProfileImageUrl!)
                : null,
            child: story.userProfileImageUrl == null
                ? Text(
                    story.username.isNotEmpty
                        ? story.username[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),

          const SizedBox(width: 12),

          // Username and time ago (always show time ago instead of views)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                // Always show time ago for all stories
                Text(
                  _formatTimeAgo(story.createdAt),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // More options button (only show for current user's stories)
          if (_isCurrentUserStory())
            IconButton(
              onPressed: onMorePressed,
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
            ),

          // Close button
          IconButton(
            onPressed: onClosePressed,
            icon: const Icon(Icons.close, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}
