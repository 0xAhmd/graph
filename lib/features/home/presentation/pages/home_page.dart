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
      final filteredPosts = filterBlockedUserPosts(currentState.posts);
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

  // Filter out posts from blocked users
  List<dynamic> filterBlockedUserPosts(List<dynamic> posts) {
    return posts
        .where((post) => !profileCubit.isUserBlocked(post.userId))
        .toList();
  }

  // Filter stories to show only from followed users
  Map<String, List<StoryEntity>> filterFollowingStories(
    Map<String, List<StoryEntity>> allStories,
  ) {
    final filteredStories = <String, List<StoryEntity>>{};

    for (final entry in allStories.entries) {
      final userId = entry.key;
      final userStories = entry.value;

      // Include stories only from users we follow (not blocked)
      if (followingUserIds.contains(userId) &&
          !profileCubit.isUserBlocked(userId)) {
        filteredStories[userId] = userStories;
      }
    }

    return filteredStories;
  }

  Widget buildPostsList(List<dynamic> posts, {bool showEmptyMessage = true}) {
    final filteredPosts = filterBlockedUserPosts(posts);

    if (filteredPosts.isEmpty && showEmptyMessage) {
      return Center(
        child: Text(
          _tabController.index == 0
              ? "No Posts Available here..."
              : "No posts from users you follow...",
          style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refreshData,
      displacement: 40,
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        itemBuilder: (context, index) {
          final post = filteredPosts[index];
          final currentUser = authCubit.currentUser;
          final isCurrentUserPost = currentUser?.uid == post.userId;
          final isUserBlocked = profileCubit.isUserBlocked(post.userId);

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
        itemCount: filteredPosts.length,
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

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  loadCommentsForPosts(filterBlockedUserPosts(allPosts));
                });

                final followingPosts = filterBlockedUserPosts(
                  allPosts
                      .where((post) => followingUserIds.contains(post.userId))
                      .toList(),
                );

                return TabBarView(
                  controller: _tabController,
                  children: [
                    /// Tab 1: For You (All posts)
                    RefreshIndicator(
                      onRefresh: refreshData,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          ...filterBlockedUserPosts(allPosts).map(
                            (post) => PostTile(
                              key: ValueKey(post.id),
                              post: post,
                              onDeletePressed: () => deletePost(post.id),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// Tab 2: Following (Stories + Posts)
                    RefreshIndicator(
                      onRefresh: refreshData,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 10),
                          buildStoriesSection(),
                          const SizedBox(height: 8),
                          if (followingPosts.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 32.0,
                              ),
                              child: Center(
                                child: Text(
                                  "No posts from people you follow.",
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.inversePrimary,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...followingPosts.map(
                              (post) => PostTile(
                                key: ValueKey(post.id),
                                post: post,
                                onDeletePressed: () => deletePost(post.id),
                              ),
                            ),
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
