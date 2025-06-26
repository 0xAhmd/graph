import '../../../auth/presentation/cubit/cubit/auth_cubit.dart';
import '../../../profile/presentation/cubit/cubit/profile_cubit.dart';
import '../../../stories/domain/entities/story.dart';

class FeedFilter {
  final AuthCubit authCubit;
  final ProfileCubit profileCubit;

  FeedFilter({required this.authCubit, required this.profileCubit});

  /// Load privacy status for all unique users in posts
  Future<Map<String, bool>> loadUserPrivacyStatus(
    List<dynamic> posts,
    Map<String, bool> existingPrivacyStatus,
  ) async {
    try {
      final uniqueUserIds = posts.map((post) => post.userId).toSet();
      final Map<String, bool> privacyMap = {};

      for (final userId in uniqueUserIds) {
        if (!existingPrivacyStatus.containsKey(userId)) {
          final userProfile = await profileCubit.getUserProfile(userId);
          if (userProfile != null) {
            privacyMap[userId] = userProfile.isPrivate;
          } else {
            privacyMap[userId] =
                false; // Default to public if profile not found
          }
        }
      }

      return privacyMap;
    } catch (e) {

      return {};
    }
  }

  /// Privacy-aware filtering for "For You" feed
  List<dynamic> filterPostsForForYouFeed(
    List<dynamic> posts,
    List<String> followingUserIds,
    Map<String, bool> userPrivacyStatus,
  ) {
    final currentUser = authCubit.currentUser;
    if (currentUser == null) return [];

    return posts.where((post) {
      // Filter out blocked users
      if (profileCubit.isUserBlocked(post.userId)) {
        return false;
      }

      // Always show own posts
      if (post.userId == currentUser.uid) {
        return true;
      }

      // Check if the post author has a private account
      final isPrivateAccount = userPrivacyStatus[post.userId] ?? false;

      if (isPrivateAccount) {
        // Only show private posts if we're following the user
        return followingUserIds.contains(post.userId);
      } else {
        // Show all public posts
        return true;
      }
    }).toList();
  }

  /// Privacy-aware filtering for "Following" feed
  List<dynamic> filterPostsForFollowingFeed(
    List<dynamic> posts,
    List<String> followingUserIds,
  ) {
    final currentUser = authCubit.currentUser;
    if (currentUser == null) return [];

    return posts.where((post) {
      // Filter out blocked users
      if (profileCubit.isUserBlocked(post.userId)) {
        return false;
      }

      // Only show posts from users we follow (including private accounts we follow)
      return followingUserIds.contains(post.userId);
    }).toList();
  }

  /// Filter stories to show only from followed users (respecting privacy)
  Map<String, List<StoryEntity>> filterFollowingStories(
    Map<String, List<StoryEntity>> allStories,
    List<String> followingUserIds,
  ) {
    final filteredStories = <String, List<StoryEntity>>{};

    for (final entry in allStories.entries) {
      final userId = entry.key;
      final userStories = entry.value;

      // Include stories only from users we follow (not blocked)
      // Stories follow the same privacy rules as posts
      if (followingUserIds.contains(userId) &&
          !profileCubit.isUserBlocked(userId)) {
        filteredStories[userId] = userStories;
      }
    }

    return filteredStories;
  }
}
