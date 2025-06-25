import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ig_mate/features/stories/presentation/cubit/story_cubit.dart';
import 'package:ig_mate/features/stories/presentation/cubit/story_state.dart';
import 'package:ig_mate/features/stories/presentation/pages/story_page.dart';
import 'package:ig_mate/features/stories/presentation/pages/story_viewer_page.dart';
import 'package:ig_mate/features/stories/presentation/widgets/story_ring.dart';
import 'package:ig_mate/features/stories/domain/entities/story.dart';
import '../../../../core/utils/app_updater.dart';
import '../../../../layout/constrained_scaffold.dart';

import '../widgets/home_drawer.dart';
import '../../../posts/presentation/cubit/post_cubit.dart';
import '../../../posts/presentation/pages/upload_post_page.dart';
import '../../../posts/presentation/widgets/post_tile.dart';
import '../../../auth/presentation/cubit/cubit/auth_cubit.dart';
import '../../../profile/presentation/cubit/cubit/profile_cubit.dart';
import '../../../comments/presentation/cubit/comment_cubit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final postCubit = context.read<PostCubit>();
  late final authCubit = context.read<AuthCubit>();
  late final profileCubit = context.read<ProfileCubit>();
  late final commentCubit = context.read<CommentCubit>();
  late TabController _tabController;

  List<String> followingUserIds = [];
  Map<String, bool> userPrivacyStatus = {}; // Track which users are private
  bool isDeleting = false;
  String? currentUserProfileImage;
  String? currentUsername;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAllPosts();
    fetchCurrentUserFollowing();
    loadBlockedUsers();
    loadCurrentUserProfile();

    // Load stories
    context.read<StoriesCubit>().fetchStories();

    AppUpdater();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void fetchAllPosts() {
    postCubit.fetchAllPosts();
  }

  Future<void> fetchCurrentUserFollowing() async {
    final currentUser = authCubit.currentUser;
    if (currentUser != null) {
      final userProfile = await profileCubit.getUserProfile(currentUser.uid);
      if (userProfile != null) {
        setState(() {
          followingUserIds = userProfile.followings;
        });
      }
    }
  }

  Future<void> loadCurrentUserProfile() async {
    final currentUser = authCubit.currentUser;
    if (currentUser != null) {
      final userProfile = await profileCubit.getUserProfile(currentUser.uid);
      if (userProfile != null) {
        setState(() {
          currentUserProfileImage = userProfile.profileImgUrl;
          currentUsername = userProfile.name.isNotEmpty
              ? userProfile.name
              : currentUser.email.split('@')[0];
        });
      }
    }
  }

  Future<void> loadBlockedUsers() async {
    final currentUser = authCubit.currentUser;
    if (currentUser != null) {
      await profileCubit.loadBlockedUsers(currentUser.uid);
    }
  }

  // NEW: Load privacy status for all unique users in posts
  Future<void> loadUserPrivacyStatus(List<dynamic> posts) async {
    try {
      final uniqueUserIds = posts.map((post) => post.userId).toSet();
      final Map<String, bool> privacyMap = {};

      for (final userId in uniqueUserIds) {
        if (!userPrivacyStatus.containsKey(userId)) {
          final userProfile = await profileCubit.getUserProfile(userId);
          if (userProfile != null) {
            privacyMap[userId] = userProfile.isPrivate;
          } else {
            privacyMap[userId] =
                false; // Default to public if profile not found
          }
        }
      }

      if (privacyMap.isNotEmpty) {
        setState(() {
          userPrivacyStatus.addAll(privacyMap);
        });
      }
    } catch (e) {
      debugPrint('Error loading user privacy status: $e');
    }
  }

  // Load comments for all visible posts
  Future<void> loadCommentsForPosts(List<dynamic> posts) async {
    try {
      for (final post in posts) {
        await commentCubit.fetchComments(post.id);
      }
    } catch (e) {
      debugPrint('Error loading comments for posts: $e');
    }
  }

  Future<void> refreshData() async {
    fetchAllPosts();
    await fetchCurrentUserFollowing();
    await loadBlockedUsers();
    await loadCurrentUserProfile();
    context.read<StoriesCubit>().fetchStories();

    await Future.delayed(const Duration(milliseconds: 500));

    final currentState = postCubit.state;
    if (currentState is PostLoaded) {
      await loadUserPrivacyStatus(currentState.posts);
      final filteredPosts = filterPostsForForYouFeed(currentState.posts);
      await loadCommentsForPosts(filteredPosts);
    }
  }

  void deletePost(String postId) async {
    setState(() {
      isDeleting = true;
    });
    await postCubit.deletePost(postId);
    setState(() {
      isDeleting = false;
    });
  }

  void blockUser(String userId) async {
    final currentUser = authCubit.currentUser;
    if (currentUser != null) {
      final shouldBlock = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Block User',
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to block this user? You won\'t see their posts anymore.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Block'),
            ),
          ],
        ),
      );

      if (shouldBlock == true) {
        await profileCubit.blockUser(currentUser.uid, userId);
        fetchAllPosts();

        if (mounted) {
          Fluttertoast.showToast(
            msg: "User Blocked!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
        }
      }
    }
  }

  void unBlockUser(String userId) async {
    final currentUser = authCubit.currentUser;
    if (currentUser != null) {
      await profileCubit.unBlockUser(currentUser.uid, userId);
      fetchAllPosts();

      if (mounted) {
        Fluttertoast.showToast(
          msg: "User unblocked!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    }
  }

  // UPDATED: Privacy-aware filtering for "For You" feed
  List<dynamic> filterPostsForForYouFeed(List<dynamic> posts) {
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

  // UPDATED: Privacy-aware filtering for "Following" feed
  List<dynamic> filterPostsForFollowingFeed(List<dynamic> posts) {
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

  // Filter stories to show only from followed users (respecting privacy)
  Map<String, List<StoryEntity>> filterFollowingStories(
    Map<String, List<StoryEntity>> allStories,
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

  Widget buildEmptyForYouMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              "No new posts yet",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Follow more people or invite friends to see more content!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(
                  context,
                ).colorScheme.inversePrimary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to discover/search page
                // You can implement this navigation
                debugPrint('Navigate to discover page');
              },
              icon: const Icon(Icons.search),
              label: const Text("Discover People"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEmptyFollowingMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              "You're not following anyone yet",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Start following accounts to see their posts here!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(
                  context,
                ).colorScheme.inversePrimary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to discover/search page
                debugPrint('Navigate to discover page');
              },
              icon: const Icon(Icons.person_add),
              label: const Text("Find People"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAddStoryButton() {
    return GestureDetector(
      onTap: () {
        debugPrint('Add story tapped');
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

  Widget buildStoriesSection() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: BlocBuilder<StoriesCubit, StoriesState>(
        builder: (context, state) {
          debugPrint('Stories state: $state');

          if (state is StoriesLoading) {
            return const Center(child: CupertinoActivityIndicator());
          } else if (state is StoriesLoaded) {
            final currentUser = authCubit.currentUser;

            // Filter stories to show only from followed users
            final filteredStories = filterFollowingStories(
              state.groupedStories,
            );

            debugPrint('Filtered stories count: ${filteredStories.length}');

            // Always show the horizontal list with "Add Story" button
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount:
                  filteredStories.length + 1, // +1 for "Add Story" button
              itemBuilder: (context, index) {
                if (index == 0) {
                  return buildAddStoryButton();
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
            debugPrint('Stories error: ${state.message}');
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
              return buildAddStoryButton();
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedScaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UploadPostPage()),
            ),
            icon: const Icon(Icons.add),
          ),
        ],
        centerTitle: true,
        title: const Text("Home"),
        bottom: TabBar(
          dividerColor: Colors.transparent,
          controller: _tabController,
          tabs: const [
            Tab(text: "For You"),
            Tab(text: "Following"),
          ],
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      drawer: const HomeDrawer(),
      body: Stack(
        children: [
          BlocBuilder<PostCubit, PostState>(
            builder: (context, state) {
              if (state is PostLoading) {
                return const Center(child: CupertinoActivityIndicator());
              } else if (state is PostLoaded) {
                final allPosts = state.posts;

                // Load privacy status for all users
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await loadUserPrivacyStatus(allPosts);
                  final forYouPosts = filterPostsForForYouFeed(allPosts);
                  await loadCommentsForPosts(forYouPosts);
                });

                final forYouPosts = filterPostsForForYouFeed(allPosts);
                final followingPosts = filterPostsForFollowingFeed(allPosts);

                return TabBarView(
                  controller: _tabController,
                  children: [
                    /// Tab 1: For You (Public posts + private posts from followed accounts)
                    RefreshIndicator(
                      onRefresh: refreshData,
                      child: forYouPosts.isEmpty
                          ? buildEmptyForYouMessage()
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: forYouPosts.length,
                              itemBuilder: (context, index) {
                                final post = forYouPosts[index];
                                final currentUser = authCubit.currentUser;
                                final isCurrentUserPost =
                                    currentUser?.uid == post.userId;
                                final isUserBlocked = profileCubit
                                    .isUserBlocked(post.userId);

                                return PostTile(
                                  key: ValueKey(post.id),
                                  post: post,
                                  onDeletePressed: () => deletePost(post.id),
                                  onBlockPressed: isCurrentUserPost
                                      ? null
                                      : () => blockUser(post.userId),
                                  onUnblockPressed: isCurrentUserPost
                                      ? null
                                      : () => unBlockUser(post.userId),
                                  isUserBlocked: isUserBlocked,
                                );
                              },
                            ),
                    ),

                    /// Tab 2: Following (Stories + Posts from followed accounts)
                    RefreshIndicator(
                      onRefresh: refreshData,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 10),
                          buildStoriesSection(),
                          const SizedBox(height: 8),
                          if (followingPosts.isEmpty)
                            buildEmptyFollowingMessage()
                          else
                            ...followingPosts.map((post) {
                              final currentUser = authCubit.currentUser;
                              final isCurrentUserPost =
                                  currentUser?.uid == post.userId;
                              final isUserBlocked = profileCubit.isUserBlocked(
                                post.userId,
                              );

                              return PostTile(
                                key: ValueKey(post.id),
                                post: post,
                                onDeletePressed: () => deletePost(post.id),
                                onBlockPressed: isCurrentUserPost
                                    ? null
                                    : () => blockUser(post.userId),
                                onUnblockPressed: isCurrentUserPost
                                    ? null
                                    : () => unBlockUser(post.userId),
                                isUserBlocked: isUserBlocked,
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                );
              } else if (state is PostError) {
                return Center(
                  child: Text(
                    state.errMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
          if (isDeleting)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(
                child: CupertinoActivityIndicator(radius: 20),
              ),
            ),
        ],
      ),
    );
  }
}
