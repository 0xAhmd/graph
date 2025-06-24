// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';

import '../pages/index.dart';

class ProfilePage extends StatefulWidget {
  final String uid;
  const ProfilePage({super.key, required this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late final authCubit = context.read<AuthCubit>();
  late final profileCubit = context.read<ProfileCubit>();
  late final storyCubit = context.read<StoriesCubit>(); // Add story cubit
  late AppUser? currentUser = authCubit.currentUser;
  bool _isFollowLoading = false;
  bool _isBlockLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 1,
      vsync: this,
    ); // Only one tab for posts
    profileCubit.fetchUserProfile(widget.uid);
    context.read<PostCubit>().fetchAllPosts();
    storyCubit.fetchStories(); // Fetch stories
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> refreshProfile() async {
    await profileCubit.fetchUserProfile(widget.uid);
    await context.read<PostCubit>().fetchAllPosts();
    storyCubit.fetchStories(); // Refresh stories too
  }

  Future<void> followButtonPressed() async {
    if (_isFollowLoading || currentUser == null) return;

    setState(() {
      _isFollowLoading = true;
    });

    try {
      await profileCubit.toggleFollow(currentUser!.uid, widget.uid);
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Failed to update follow stats",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFollowLoading = false;
        });
      }
    }
  }

  Future<void> _showOptionsBottomSheet(
    BuildContext context,
    AppUser user,
  ) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Block user option
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: Text(
                  'Block ${user.name}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  _showBlockConfirmationDialog(context, user);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.report_gmailerrorred_outlined,
                  color: Colors.amber,
                ),
                title: Text(
                  'Report ${user.name}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context); // Close bottom sheet
                  await Future.delayed(const Duration(seconds: 2));

                  Fluttertoast.showToast(
                    msg: "${user.name} has been reported",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                  );
                },
              ),
              // Cancel option
              ListTile(
                leading: const Icon(Icons.cancel_outlined),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showBlockConfirmationDialog(
    BuildContext context,
    AppUser user,
  ) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Block ${user.name}?'),
          content: Text(
            'Are you sure you want to block ${user.name}? You won\'t be able to see their posts, stories, or profile.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _blockUser(user);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Block'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _blockUser(AppUser user) async {
    if (_isBlockLoading || currentUser == null) return;

    setState(() {
      _isBlockLoading = true;
    });

    try {
      // Call your block user method from ProfileCubit
      // You'll need to implement this method in your ProfileCubit
      await profileCubit.blockUser(currentUser!.uid, widget.uid);

      if (mounted) {
        Fluttertoast.showToast(
          msg: "${user.name} has been blocked",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // Navigate back to previous screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Failed to block user: $e",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBlockLoading = false;
        });
      }
    }
  }

  void _navigateToPostPreview(List<Post> userPosts, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostPreviewPage(
          userPosts: userPosts,
          initialIndex: index,
          userId: widget.uid,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isOwn = (widget.uid == currentUser!.uid);
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        return BlocBuilder<PostCubit, PostState>(
          builder: (context, postState) {
            return BlocBuilder<StoriesCubit, StoriesState>(
              builder: (context, storyState) {
                if (profileState is ProfileLoaded) {
                  final user = profileState.profileUserEntity;

                  final List<Post> userPosts = (postState is PostLoaded)
                      ? postState.posts
                            .where((post) => post.userId == widget.uid)
                            .toList()
                      : <Post>[];

                  // Filter user's stories
                  final List<StoryEntity> userStories =
                      (storyState is StoriesLoaded)
                      ? storyState.stories
                            .where((story) => story.userId == widget.uid)
                            .toList()
                      : <StoryEntity>[];

                  return ConstrainedScaffold(
                    appBar: AppBar(
                      actions: [
                        if (isOwn)
                          IconButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditProfilePage(profileUserEntity: user),
                                ),
                              );
                              refreshProfile();
                            },
                            icon: const Icon(Icons.settings),
                          )
                        else
                          // Options icon for other users' profiles
                          _isBlockLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CupertinoActivityIndicator(),
                                  ),
                                )
                              : IconButton(
                                  onPressed: () =>
                                      _showOptionsBottomSheet(context, user),
                                  icon: const Icon(Icons.more_vert),
                                ),
                      ],
                      centerTitle: true,
                      title: Text(user.name),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    body: RefreshIndicator(
                      onRefresh: () {
                        return refreshProfile();
                      },
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),

                              // Profile image with story ring if user has stories
                              GestureDetector(
                                onTap: userStories.isNotEmpty
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                StoryViewerPage(
                                                  stories: userStories,
                                                  initialIndex: 0,
                                                ),
                                          ),
                                        );
                                      }
                                    : null,
                                child: Container(
                                  width: 170,
                                  height: 170,
                                  decoration: userStories.isNotEmpty
                                      ? const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFFF58529),
                                              Color(0xFFDD2A7B),
                                              Color(0xFF8134AF),
                                              Color(0xFF515BD4),
                                            ],
                                            begin: Alignment.topRight,
                                            end: Alignment.bottomLeft,
                                          ),
                                        )
                                      : null,
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                      userStories.isNotEmpty ? 5.0 : 0,
                                    ),
                                    child: ProfileImageViewer(
                                      imageUrl: user.profileImgUrl,
                                      size: 160,
                                      heroTag: 'profile-image',
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),
                              Text(
                                user.email,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 25),

                              ProfileStats(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FollowerPage(
                                        followers: user.followers,
                                        followings: user.followings,
                                      ),
                                    ),
                                  );
                                },
                                postCount: userPosts.length,
                                followersCount: user.followers.length,
                                followingCount: user.followings.length,
                              ),

                              const SizedBox(height: 25),
                              if (!isOwn)
                                _isFollowLoading
                                    ? const CupertinoActivityIndicator()
                                    : FollowButton(
                                        isFollowing: user.followers.contains(
                                          currentUser!.uid,
                                        ),
                                        onTap: followButtonPressed,
                                      ),

                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Row(
                                  children: [
                                    Text(
                                      "Bio",
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              BioBox(text: user.bio),

                              // Tab Bar and Posts Grid
                              Padding(
                                padding: const EdgeInsets.only(top: 25),
                                child: Column(
                                  children: [
                                    // Tab Bar
                                    TabBar(
                                      dividerColor: Colors.transparent,
                                      controller: _tabController,
                                      indicatorColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      tabs: const [
                                        Tab(icon: Icon(Icons.grid_on)),
                                      ],
                                    ),

                                    // Posts Grid
                                    SizedBox(
                                      height: 400, // Fixed height for the grid
                                      child: TabBarView(
                                        controller: _tabController,
                                        children: [
                                          if (postState is PostLoading)
                                            const Center(
                                              child:
                                                  CupertinoActivityIndicator(),
                                            )
                                          else
                                            ProfilePostsGrid(
                                              posts: userPosts,
                                              onPostTap: (index) =>
                                                  _navigateToPostPreview(
                                                    userPosts,
                                                    index,
                                                  ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                } else if (profileState is ProfileLoading ||
                    profileState is ProfileImageUploading) {
                  return const ConstrainedScaffold(
                    body: Center(child: CupertinoActivityIndicator()),
                  );
                } else if (profileState is ProfileError) {
                  return ConstrainedScaffold(
                    body: Center(
                      child: Text(
                        profileState.errMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                } else {
                  return const ConstrainedScaffold(
                    body: Center(child: Text("No Profile Loaded")),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
