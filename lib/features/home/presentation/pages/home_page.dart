import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ig_mate/features/stories/presentation/cubit/story_cubit.dart';
import 'package:ig_mate/features/stories/presentation/cubit/story_state.dart';
import 'package:ig_mate/features/stories/presentation/pages/story_page.dart';
import 'package:ig_mate/features/stories/presentation/pages/story_viewer_page.dart';
import 'package:ig_mate/features/stories/presentation/widgets/story_ring.dart';
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
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAllPosts();
    fetchCurrentUserFollowing();
    loadBlockedUsers();

    // Add this line to load stories
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

  Future<void> loadBlockedUsers() async {
    final currentUser = authCubit.currentUser;
    if (currentUser != null) {
      await profileCubit.loadBlockedUsers(currentUser.uid);
    }
  }

  // Load comments for all visible posts
  Future<void> loadCommentsForPosts(List<dynamic> posts) async {
    try {
      // Load comments for each post
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
    context.read<StoriesCubit>().fetchStories();

    // Wait a bit for posts to load, then load comments
    await Future.delayed(const Duration(milliseconds: 500));

    // Get current posts and load their comments
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
      // Show confirmation dialog
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
        // Refresh posts to remove blocked user's posts
        fetchAllPosts();

        // Show success message
        if (mounted) {
          Fluttertoast.showToast(
            msg: "User Blocked!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green, // or Colors.green, etc.
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
      // Refresh posts to show unblocked user's posts
      fetchAllPosts();

      // Show success message
      if (mounted) {
        Fluttertoast.showToast(
          msg: "User unblocked!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green, // or Colors.green, etc.
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

  Widget buildPostsList(List<dynamic> posts, {bool showEmptyMessage = true}) {
    // Filter out blocked users' posts
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
            key: ValueKey(post.id), // ✅ important
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

                // Load comments for all posts when posts are loaded
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  loadCommentsForPosts(filterBlockedUserPosts(allPosts));
                });

                // Filter posts for following tab (also filter out blocked users)
                final followingPosts = filterBlockedUserPosts(
                  allPosts
                      .where((post) => followingUserIds.contains(post.userId))
                      .toList(),
                );

                // Add to HomePage after the AppBar and before the TabBarView
                Container(
                  height: 120,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: BlocBuilder<StoriesCubit, StoriesState>(
                    builder: (context, state) {
                      if (state is StoriesLoaded) {
                        final currentUser = authCubit.currentUser;
                        final userStories = state.groupedStories;

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount:
                              userStories.length +
                              1, // +1 for "Add Story" button
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              // Add Story button
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CreateStoryPage(),
                                  ),
                                ),
                                child: Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 70,
                                        height: 70,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red,
                                        ),
                                        child: Icon(
                                          Icons.add,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                          size: 30,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Your Story',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.inversePrimary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final userId = userStories.keys.elementAt(
                              index - 1,
                            );
                            final stories = userStories[userId]!;
                            final hasUnviewed = stories.any(
                              (story) =>
                                  currentUser != null &&
                                  !story.viewers.contains(currentUser.uid),
                            );

                            return StoryRing(
                              userStories: stories,
                              hasUnviewedStories: hasUnviewed,
                              profileImageUrl:
                                  stories.first.userProfileImageUrl,
                              username: stories.first.username,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StoryViewerPage(
                                    stories: stories,
                                    initialIndex: 0,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }
                      return const SizedBox(height: 120);
                    },
                  ),
                );

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // For You Tab - All Posts (filtered) with Stories
                    Column(
                      children: [
                        // Add this import at the top
                        const SizedBox(height: 10),
                        // Replace the stories container in your TabBarView with this:
                        Container(
                          height: 120,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: BlocBuilder<StoriesCubit, StoriesState>(
                            builder: (context, state) {
                              print('Stories state: $state'); // Debug print

                              if (state is StoriesLoading) {
                                return const Center(
                                  child: CupertinoActivityIndicator(),
                                );
                              } else if (state is StoriesLoaded) {
                                final currentUser = authCubit.currentUser;
                                final userStories = state.groupedStories;

                                print(
                                  'User stories count: ${userStories.length}',
                                ); // Debug print

                                return ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount:
                                      userStories.length +
                                      1, // +1 for "Add Story" button
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      // Add Story button
                                      return GestureDetector(
                                        onTap: () {
                                          print(
                                            'Add story tapped',
                                          ); // Debug print
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const CreateStoryPage(), // or CreateStoryPage()
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: 80,
                                          margin: const EdgeInsets.only(
                                            right: 12,
                                          ),
                                          child: Column(
                                            children: [
                                              Container(
                                                width: 70,
                                                height: 70,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  border: Border.all(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.add,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onPrimary,
                                                  size: 30,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Your Story',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.inversePrimary,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    final userId = userStories.keys.elementAt(
                                      index - 1,
                                    );
                                    final stories = userStories[userId]!;
                                    final hasUnviewed = stories.any(
                                      (story) =>
                                          currentUser != null &&
                                          !story.viewers.contains(
                                            currentUser.uid,
                                          ),
                                    );

                                    return StoryRing(
                                      userStories: stories,
                                      hasUnviewedStories: hasUnviewed,
                                      profileImageUrl:
                                          stories.first.userProfileImageUrl,
                                      username: stories.first.username,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => StoryViewerPage(
                                            stories: stories,
                                            initialIndex: 0,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              } else if (state is StoriesError) {
                                print(
                                  'Stories error: ${state.message}',
                                ); // Debug print
                                return Center(
                                  child: Text(
                                    'Error loading stories',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                );
                              }

                              return const SizedBox(height: 120);
                            },
                          ),
                        ),

                        // Posts List
                        Expanded(child: buildPostsList(allPosts)),
                      ],
                    ),

                    // Following Tab - Only posts from users you follow (filtered) with RefreshIndicator
                    RefreshIndicator(
                      onRefresh: refreshData,
                      displacement: 40,
                      color: Theme.of(context).colorScheme.primary,
                      child: followingPosts.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
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
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: followingPosts.length,
                              itemBuilder: (context, index) {
                                final post = followingPosts[index];
                                return PostTile(
                                  key: ValueKey(post.id),
                                  post: post,
                                  onDeletePressed: () => deletePost(post.id),
                                );
                              },
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
