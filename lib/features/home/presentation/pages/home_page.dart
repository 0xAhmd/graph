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

  Future<void> refreshData() async {
    fetchAllPosts();
    await fetchCurrentUserFollowing();
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

  Widget buildPostsList(List<dynamic> posts, {bool showEmptyMessage = true}) {
    if (posts.isEmpty && showEmptyMessage) {
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
          final post = posts[index];
          return PostTile(
            post: post,
            onDeletePressed: () => deletePost(post.id),
          );
        },
        itemCount: posts.length,
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

                // Filter posts for following tab
                final followingPosts = allPosts
                    .where((post) => followingUserIds.contains(post.userId))
                    .toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // For You Tab - All Posts
                    buildPostsList(allPosts),

                    // Following Tab - Only posts from users you follow
                    buildPostsList(followingPosts),
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
