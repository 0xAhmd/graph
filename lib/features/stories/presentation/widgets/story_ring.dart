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
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasUnviewedStories
                    ? const LinearGradient(
                        colors: [Colors.purple, Colors.pink, Colors.orange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: !hasUnviewedStories
                    ? Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.3),
                        width: 2,
                      )
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            profileImageUrl == null || profileImageUrl!.isEmpty
                            ? Theme.of(context).colorScheme.surfaceVariant
                            : null,
                      ),
                      child:
                          profileImageUrl != null && profileImageUrl!.isNotEmpty
                          ? Image.network(
                              profileImageUrl!,
                              fit: BoxFit.cover,
                              width: 64,
                              height: 64,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceVariant,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    size: 32,
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surfaceVariant,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                    );
                                  },
                            )
                          : Icon(
                              Icons.person,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              size: 32,
                            ),
                    ),
                  ),
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
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
