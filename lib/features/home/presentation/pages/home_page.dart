import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/home_drawer.dart';
import '../../../posts/presentation/cubit/post_cubit.dart';
import '../../../posts/presentation/pages/upload_post_page.dart';
import '../../../posts/presentation/widgets/post_tile.dart';
import '../../../auth/presentation/cubit/cubit/auth_cubit.dart';
import '../../../profile/presentation/cubit/cubit/profile_cubit.dart';

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

  Future<void> refreshData() async {
    fetchAllPosts();
    await fetchCurrentUserFollowing();
    await loadBlockedUsers();
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User blocked successfully'),
              duration: Duration(seconds: 2),
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User unblocked successfully'),
            duration: Duration(seconds: 2),
          ),
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
    return Scaffold(
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

                // Filter posts for following tab (also filter out blocked users)
                final followingPosts = filterBlockedUserPosts(
                  allPosts
                      .where((post) => followingUserIds.contains(post.userId))
                      .toList(),
                );

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // For You Tab - All Posts (filtered)
                    buildPostsList(allPosts),

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
