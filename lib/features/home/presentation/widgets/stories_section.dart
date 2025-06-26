import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../stories/presentation/cubit/story_cubit.dart';
import '../../../stories/presentation/cubit/story_state.dart';
import '../../../stories/presentation/pages/story_page.dart';
import '../../../stories/presentation/pages/story_viewer_page.dart';
import '../../../stories/presentation/widgets/story_ring.dart';


import '../../../auth/presentation/cubit/cubit/auth_cubit.dart';
import '../../../profile/presentation/cubit/cubit/profile_cubit.dart';
import '../../../home/domain/utils/feed_filter.dart';

class StoriesSection extends StatelessWidget {
  final List<String> followingUserIds;
  final String? currentUserProfileImage;

  const StoriesSection({
    super.key,
    required this.followingUserIds,
    required this.currentUserProfileImage,
  });

  Widget _buildAddStoryButton(BuildContext context) {
    return GestureDetector(
      onTap: () {

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateStoryPage()),
        );
      },
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
                image:
                    currentUserProfileImage != null &&
                        currentUserProfileImage!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(currentUserProfileImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color:
                    currentUserProfileImage == null ||
                        currentUserProfileImage!.isEmpty
                    ? Theme.of(context).colorScheme.surfaceVariant
                    : null,
              ),
              child: Stack(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image:
                          currentUserProfileImage != null &&
                              currentUserProfileImage!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(currentUserProfileImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color:
                          currentUserProfileImage == null ||
                              currentUserProfileImage!.isEmpty
                          ? Theme.of(context).colorScheme.surfaceVariant
                          : null,
                    ),
                    child:
                        currentUserProfileImage == null ||
                            currentUserProfileImage!.isEmpty
                        ? Icon(
                            Icons.person,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            size: 30,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your Story',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedFilter = FeedFilter(
      authCubit: context.read<AuthCubit>(),
      profileCubit: context.read<ProfileCubit>(),
    );

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: BlocBuilder<StoriesCubit, StoriesState>(
        builder: (context, state) {

          if (state is StoriesLoading) {
            return const Center(child: CupertinoActivityIndicator());
          } else if (state is StoriesLoaded) {
            final currentUser = context.read<AuthCubit>().currentUser;

            // Filter stories to show only from followed users
            final filteredStories = feedFilter.filterFollowingStories(
              state.groupedStories,
              followingUserIds,
            );

            // Always show the horizontal list with "Add Story" button
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount:
                  filteredStories.length + 1, // +1 for "Add Story" button
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildAddStoryButton(context);
                }

                final userId = filteredStories.keys.elementAt(index - 1);
                final stories = filteredStories[userId]!;
                final hasUnviewed = stories.any(
                  (story) =>
                      currentUser != null &&
                      !story.viewers.contains(currentUser.uid),
                );

                return StoryRing(
                  userStories: stories,
                  hasUnviewedStories: hasUnviewed,
                  profileImageUrl: stories.first.userProfileImageUrl,
                  username: stories.first.username,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          StoryViewerPage(stories: stories, initialIndex: 0),
                    ),
                  ),
                );
              },
            );
          } else if (state is StoriesError) {

            return Center(
              child: Text(
                'Error loading stories',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }

          // For initial/empty state, still show the "Add Story" button
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 1, // Only "Add Story" button
            itemBuilder: (context, index) {
              return _buildAddStoryButton(context);
            },
          );
        },
      ),
    );
  }
}
