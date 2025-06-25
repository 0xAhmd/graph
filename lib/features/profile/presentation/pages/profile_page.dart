// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ig_mate/features/auth/presentation/cubit/cubit/auth_cubit.dart';
import 'package:ig_mate/features/posts/domain/entities/post_entity.dart';
import 'package:ig_mate/features/profile/domain/entities/profile_user.dart';
import 'package:ig_mate/features/profile/presentation/cubit/cubit/profile_cubit.dart';
import 'package:ig_mate/features/profile/presentation/widgets/preview_page.dart';
import 'package:ig_mate/features/profile/presentation/widgets/profile_grid.dart';
import 'package:ig_mate/features/stories/presentation/cubit/story_cubit.dart';
import 'package:ig_mate/features/stories/presentation/cubit/story_state.dart';
import 'package:ig_mate/layout/constrained_scaffold.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../posts/presentation/cubit/post_cubit.dart';
import '../../../stories/domain/entities/story.dart';
import '../../../stories/presentation/pages/story_viewer_page.dart';
import '../../../private/domain/entities/follow_request.dart';
import '../../../private/presentation/cubit/follow_request_cubit.dart';
import '../../../private/presentation/cubit/privacy_cubit.dart';

import '../widgets/follow_button.dart';
import '../widgets/profile_image_viewer.dart';
import '../widgets/profile_stats.dart';
import '../widgets/bio_box.dart';
import '../pages/edit_profile_page.dart';
import '../pages/follower_page.dart';

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
  late final storyCubit = context.read<StoriesCubit>();
  late final followRequestCubit = context.read<FollowRequestCubit>();
  late final privacyCubit = context.read<PrivacyCubit>();
  late AppUser? currentUser = authCubit.currentUser;
  bool _isFollowLoading = false;
  bool _isBlockLoading = false;
  late TabController _tabController;
  FollowRequestEntity? _followRequest;
  String? _lastLoadedUid; // Track the last loaded UID

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // CRITICAL FIX: Reset state when UID changes
    if (oldWidget.uid != widget.uid) {
      // Reset all state variables
      _isFollowLoading = false;
      _isBlockLoading = false;
      _followRequest = null;
      _lastLoadedUid = null; // Reset the tracked UID

      // Re-initialize data for new UID
      _initializeData();
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _initializeData();
  }

  // REMOVE the didChangeDependencies method - it's causing issues
  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   // Remove this - it's causing unnecessary refreshes
  // }

  Future<void> _initializeData() async {
    // Only initialize if we haven't loaded this UID yet or if it's different
    if (_lastLoadedUid != widget.uid) {
      _lastLoadedUid = widget.uid;

      profileCubit.fetchUserProfile(widget.uid);
      context.read<PostCubit>().fetchAllPosts();
      storyCubit.fetchStories();

      // Load follow request data if not own profile
      if (!_isOwnProfile) {
        followRequestCubit.loadFollowRequests(currentUser!.uid);
        _loadFollowRequest();
      }
    }
  }

  Future<void> _loadFollowRequest() async {
    if (currentUser == null) return;

    final request = await followRequestCubit.getFollowRequestBetweenUsers(
      fromUserId: currentUser!.uid,
      toUserId: widget.uid,
    );

    if (mounted) {
      setState(() {
        _followRequest = request;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isOwnProfile => (widget.uid == currentUser?.uid);

  Future<void> refreshProfile() async {
    await profileCubit.fetchUserProfile(widget.uid);
    await context.read<PostCubit>().fetchAllPosts();
    storyCubit.fetchStories();

    if (!_isOwnProfile) {
      followRequestCubit.loadFollowRequests(currentUser!.uid);
      _loadFollowRequest();
    }
  }

  // ... rest of your methods stay the same ...

  FollowButtonState _getFollowButtonState(ProfileUserEntity user) {
    final isFollowing = user.followers.contains(currentUser!.uid);
    final hasRequestSent =
        _followRequest != null &&
        _followRequest!.status == FollowRequestStatus.pending;

    return FollowButtonStateHelper.determineState(
      isFollowing: isFollowing,
      isPrivate: user.isPrivate,
      hasRequestSent: hasRequestSent,
    );
  }

  Future<void> _handleFollowButtonPressed(ProfileUserEntity user) async {
    if (_isFollowLoading || currentUser == null) return;

    setState(() {
      _isFollowLoading = true;
    });

    try {
      final followButtonState = _getFollowButtonState(user);

      switch (followButtonState) {
        case FollowButtonState.follow:
          // Direct follow for public profiles
          await profileCubit.toggleFollow(currentUser!.uid, widget.uid);
          break;

        case FollowButtonState.sendRequest:
          // Send follow request for private profiles
          await followRequestCubit.sendFollowRequest(
            fromUserId: currentUser!.uid,
            toUserId: widget.uid,
          );
          await _loadFollowRequest();
          break;

        case FollowButtonState.following:
          // Unfollow
          await profileCubit.toggleFollow(currentUser!.uid, widget.uid);
          break;

        case FollowButtonState.requestSent:
          // Cancel follow request
          await followRequestCubit.cancelFollowRequest(
            fromUserId: currentUser!.uid,
            toUserId: widget.uid,
          );
          await _loadFollowRequest();
          break;
      }

      // Refresh profile data
      await refreshProfile();
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Failed to update follow status",
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
    ProfileUserEntity user,
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
                  Navigator.pop(context);
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
                  Navigator.pop(context);
                  await Future.delayed(const Duration(seconds: 1));
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
    ProfileUserEntity user,
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
                Navigator.pop(context);
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

  Future<void> _blockUser(ProfileUserEntity user) async {
    if (_isBlockLoading || currentUser == null) return;

    setState(() {
      _isBlockLoading = true;
    });

    try {
      await profileCubit.blockUser(currentUser!.uid, widget.uid);

      if (mounted) {
        Fluttertoast.showToast(
          msg: "${user.name} has been blocked",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

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

  Widget _buildPrivateAccountMessage() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.lock_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'This Account is Private',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Follow this account to see their photos and videos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  bool _canViewContent(ProfileUserEntity user) {
    if (_isOwnProfile) return true;
    if (!user.isPrivate) return true;
    return user.followers.contains(currentUser?.uid);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        return BlocBuilder<PostCubit, PostState>(
          builder: (context, postState) {
            return BlocBuilder<StoriesCubit, StoriesState>(
              builder: (context, storyState) {
                if (profileState is ProfileLoaded) {
                  final user = profileState.profileUserEntity;
                  final canViewContent = _canViewContent(user);

                  final List<Post> userPosts =
                      (postState is PostLoaded && canViewContent)
                      ? postState.posts
                            .where((post) => post.userId == widget.uid)
                            .toList()
                      : <Post>[];

                  final List<StoryEntity> userStories =
                      (storyState is StoriesLoaded && canViewContent)
                      ? storyState.stories
                            .where((story) => story.userId == widget.uid)
                            .toList()
                      : <StoryEntity>[];

                  return ConstrainedScaffold(
                    appBar: AppBar(
                      actions: [
                        if (_isOwnProfile)
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfilePage(
                                      profileUserEntity: user,
                                    ),
                                  ),
                                );
                                refreshProfile();
                              } else if (value == 'toggle_privacy') {
                                await privacyCubit.togglePrivacy(
                                  user.uid,
                                  !user.isPrivate,
                                );
                                refreshProfile();
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem<String>(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text('Edit Profile'),
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'toggle_privacy',
                                child: ListTile(
                                  leading: const Icon(Icons.lock),
                                  title: Text(
                                    user.isPrivate
                                        ? 'Set to Public'
                                        : 'Set to Private',
                                  ),
                                ),
                              ),
                            ],
                            icon: const Icon(Icons.settings),
                          )
                        else
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
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(user.name),
                          if (user.isPrivate) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.lock_outline, size: 16),
                          ],
                        ],
                      ),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    body: RefreshIndicator(
                      onRefresh: refreshProfile,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),

                              // Profile image with story ring
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
                                onTap: canViewContent
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FollowerPage(
                                              followers: user.followers,
                                              followings: user.followings,
                                              originalProfileUid: widget
                                                  .uid, // Pass the current profile UID
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                postCount: canViewContent
                                    ? userPosts.length
                                    : 0,
                                followersCount: user.followers.length,
                                followingCount: canViewContent
                                    ? user.followings.length
                                    : 0,
                              ),
                              const SizedBox(height: 25),

                              // Follow button for non-own profiles
                              if (!_isOwnProfile)
                                _isFollowLoading
                                    ? const CupertinoActivityIndicator()
                                    : FollowButton(
                                        followButtonState:
                                            _getFollowButtonState(user),
                                        onTap: () =>
                                            _handleFollowButtonPressed(user),
                                        isLoading: _isFollowLoading,
                                      ),

                              // Bio section
                              if (canViewContent) ...[
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
                              ],

                              // Content section
                              Padding(
                                padding: const EdgeInsets.only(top: 25),
                                child: Column(
                                  children: [
                                    if (canViewContent) ...[
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
                                        height: 400,
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
                                    ] else ...[
                                      // Private profile message
                                      SizedBox(
                                        height: 400,
                                        child: _buildPrivateAccountMessage(),
                                      ),
                                    ],
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
