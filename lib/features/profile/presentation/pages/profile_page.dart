// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ig_mate/features/profile/presentation/widgets/profile_image_viewer.dart';
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
  late AppUser? currentUser = authCubit.currentUser;
  bool _isFollowLoading = false;
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> refreshProfile() async {
    await profileCubit.fetchUserProfile(widget.uid);
    await context.read<PostCubit>().fetchAllPosts();
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
            if (profileState is ProfileLoaded) {
              final user = profileState.profileUserEntity;

              final List<Post> userPosts = (postState is PostLoaded)
                  ? postState.posts
                        .where((post) => post.userId == widget.uid)
                        .toList()
                  : <Post>[];

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
                          ProfileImageViewer(
                            imageUrl: user.profileImgUrl,
                            size: 160,
                            heroTag: 'profile-image',
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
                                  tabs: const [Tab(icon: Icon(Icons.grid_on))],
                                ),

                                // Posts Grid
                                SizedBox(
                                  height: 400, // Fixed height for the grid
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      if (postState is PostLoading)
                                        const Center(
                                          child: CupertinoActivityIndicator(),
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
  }
}
