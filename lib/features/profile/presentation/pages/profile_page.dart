// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ig_mate/features/auth/domain/entities/app_user.dart';
import 'package:ig_mate/features/auth/presentation/cubit/cubit/auth_cubit.dart';
import 'package:ig_mate/features/posts/presentation/cubit/post_cubit.dart';
import 'package:ig_mate/features/posts/presentation/widgets/post_tile.dart';
import 'package:ig_mate/features/profile/presentation/cubit/cubit/profile_cubit.dart';
import 'package:ig_mate/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:ig_mate/features/profile/presentation/pages/follower_page.dart';
import 'package:ig_mate/features/profile/presentation/widgets/bio_box.dart';
import 'package:ig_mate/features/profile/presentation/widgets/follow_button.dart';
import 'package:ig_mate/features/profile/presentation/widgets/profile_stats.dart';

class ProfilePage extends StatefulWidget {
  final String uid;
  const ProfilePage({super.key, required this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final authCubit = context.read<AuthCubit>();
  late final profileCubit = context.read<ProfileCubit>();
  late AppUser? currentUser = authCubit.currentUser;
  bool _isFollowLoading = false; // Add loading state for follow button

  @override
  void initState() {
    super.initState();
    profileCubit.fetchUserProfile(widget.uid);
    context.read<PostCubit>().fetchAllPosts();
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
      // Show error message to user
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Failed to update follow stats",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red, // or Colors.green, etc.
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

  @override
  Widget build(BuildContext context) {
    bool isOwn = (widget.uid == currentUser!.uid);
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        return BlocBuilder<PostCubit, PostState>(
          builder: (context, postState) {
            if (profileState is ProfileLoaded) {
              final user = profileState.profileUserEntity;

              final userPosts = (postState is PostLoaded)
                  ? postState.posts
                        .where((post) => post.userId == widget.uid)
                        .toList()
                  : [];

              return Scaffold(
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
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        GestureDetector(
                          onLongPress: () {
                            if (user.profileImgUrl.isNotEmpty) {
                              showDialog(
                                context: context,
                                barrierDismissible: true,
                                barrierColor: Colors.black.withOpacity(0.5),
                                builder: (context) {
                                  return GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Stack(
                                      children: [
                                        BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 10,
                                            sigmaY: 10,
                                          ),
                                          child: Container(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Hero(
                                            tag: 'profile-image',
                                            child: ClipOval(
                                              child: CachedNetworkImage(
                                                imageUrl: user.profileImgUrl,
                                                width:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width *
                                                    0.8,
                                                height:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width *
                                                    0.8,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }
                          },
                          child: Hero(
                            tag: 'profile-image',
                            child: CachedNetworkImage(
                              imageUrl: user.profileImgUrl,
                              imageBuilder: (context, imageProvider) =>
                                  Container(
                                    width: 160,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                              placeholder: (context, url) => Container(
                                width: 120,
                                height: 120,
                                padding: const EdgeInsets.all(25),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                                child: const CupertinoActivityIndicator(),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 150,
                                height: 160,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 70,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
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
                          // FIXED: Show loading state in follow button
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
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        BioBox(text: user.bio),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, top: 25),
                          child: Row(
                            children: [
                              Text(
                                "Posts",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (postState is PostLoading)
                          const CupertinoActivityIndicator()
                        else if (userPosts.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32.0),
                            child: Center(child: Text("No posts yet.")),
                          )
                        else
                          ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: userPosts.length,
                            itemBuilder: (context, index) {
                              final post = userPosts[index];
                              return PostTile(
                                post: post,
                                onDeletePressed: () => context
                                    .read<PostCubit>()
                                    .deletePost(post.id),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              );
            } else if (profileState is ProfileLoading ||
                profileState is ProfileImageUploading) {
              return const Scaffold(
                body: Center(child: CupertinoActivityIndicator()),
              );
            } else if (profileState is ProfileError) {
              return Scaffold(
                body: Center(
                  child: Text(
                    profileState.errMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            } else {
              return const Scaffold(
                body: Center(child: Text("No Profile Loaded")),
              );
            }
          },
        );
      },
    );
  }
}
