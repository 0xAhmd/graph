
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../domain/utils/feed_filter.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../../../stories/presentation/cubit/story_cubit.dart';

import '../../../../core/utils/app_updater.dart';
import '../../../../layout/constrained_scaffold.dart';
import '../widgets/home_drawer.dart';
import '../widgets/for_you_feed.dart';
import '../widgets/following_feed.dart';
import '../../../posts/presentation/cubit/post_cubit.dart';
import '../../../posts/presentation/pages/upload_post_page.dart';
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
  late final FeedFilter _feedFilter;

  List<String> followingUserIds = [];
  Map<String, bool> userPrivacyStatus = {};
  bool isDeleting = false;
  String? currentUserProfileImage;
  String? currentUsername;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _feedFilter = FeedFilter(authCubit: authCubit, profileCubit: profileCubit);

    // Defer initialization to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
      AppUpdater.checkForUpdate(context);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    fetchAllPosts();
    await fetchCurrentUserFollowing();
    await loadBlockedUsers();
    await loadCurrentUserProfile();
    context.read<StoriesCubit>().fetchStories();
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

  Future<void> loadUserPrivacyStatus(List<dynamic> posts) async {
    try {
      final privacyMap = await _feedFilter.loadUserPrivacyStatus(
        posts,
        userPrivacyStatus,
      );

      if (privacyMap.isNotEmpty) {
        setState(() {
          userPrivacyStatus.addAll(privacyMap);
        });
      }
    } catch (e) {
      debugPrint(e.toString());

    }
  }

  Future<void> loadCommentsForPosts(List<dynamic> posts) async {
    try {
      for (final post in posts) {
        await commentCubit.fetchComments(post.id);
      }
    } catch (e) {
      debugPrint(e.toString());

    }
  }

  Future<void> refreshData() async {
    await _initializeData();
    await Future.delayed(const Duration(milliseconds: 500));

    final currentState = postCubit.state;
    if (currentState is PostLoaded) {
      await loadUserPrivacyStatus(currentState.posts);
      final filteredPosts = _feedFilter.filterPostsForForYouFeed(
        currentState.posts,
        followingUserIds,
        userPrivacyStatus,
      );
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
                  final forYouPosts = _feedFilter.filterPostsForForYouFeed(
                    allPosts,
                    followingUserIds,
                    userPrivacyStatus,
                  );
                  await loadCommentsForPosts(forYouPosts);
                });

                final forYouPosts = _feedFilter.filterPostsForForYouFeed(
                  allPosts,
                  followingUserIds,
                  userPrivacyStatus,
                );
                final followingPosts = _feedFilter.filterPostsForFollowingFeed(
                  allPosts,
                  followingUserIds,
                );

                return TabBarView(
                  controller: _tabController,
                  children: [
                    ForYouFeed(
                      posts: forYouPosts,
                      onRefresh: refreshData,
                      onDeletePost: deletePost,
                      onBlockUser: blockUser,
                      onUnblockUser: unBlockUser,
                      onNavigateToDiscover: () {

                      },
                    ),
                    FollowingFeed(
                      posts: followingPosts,
                      followingUserIds: followingUserIds,
                      currentUserProfileImage: currentUserProfileImage,
                      onRefresh: refreshData,
                      onDeletePost: deletePost,
                      onBlockUser: blockUser,
                      onUnblockUser: unBlockUser,
                      onNavigateToSearch: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchPage(),
                          ),
                        );
                      },
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
