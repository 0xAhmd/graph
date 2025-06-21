// lib/features/stories/presentation/widgets/story_ring.dart
import 'package:flutter/material.dart';
import 'package:ig_mate/features/stories/domain/entities/story.dart';

class StoryRing extends StatelessWidget {
  final List<StoryEntity> userStories;
  final VoidCallback onTap;
  final bool hasUnviewedStories;
  final String? profileImageUrl;
  final String username;

  const StoryRing({
    super.key,
    required this.userStories,
    required this.onTap,
    required this.hasUnviewedStories,
    this.profileImageUrl,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasUnviewedStories
                    ? const LinearGradient(
                        colors: [Colors.purple, Colors.pink, Colors.orange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: hasUnviewedStories
                    ? null
                    : Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 2,
                      ),
              ),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: profileImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(profileImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: profileImageUrl == null
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  child: profileImageUrl == null
                      ? Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              username.length > 10
                  ? '${username.substring(0, 10)}...'
                  : username,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
