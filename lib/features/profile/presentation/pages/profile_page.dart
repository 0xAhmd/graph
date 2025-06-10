// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  int postCount = 0;

  @override
  void initState() {
    super.initState();
    profileCubit.fetchUserProfile(widget.uid);
  }

  Future<void> refreshProfile() async {
    await profileCubit.fetchUserProfile(widget.uid);
  }

  void followButtonPressed() {
    final profileState = profileCubit.state;

    if (profileState is! ProfileLoaded) {
      return;
    }
    final profileUser = profileState.profileUserEntity;
    final isFollowing = profileUser.followers.contains(currentUser!.uid);

    setState(() {
      if (isFollowing) {
        profileUser.followers.remove(currentUser!.uid);
      } else {
        profileUser.followers.add(currentUser!.uid);
      }
    });
    profileCubit.toggleFollow(currentUser!.uid, widget.uid).catchError((error) {
      setState(() {
        if (isFollowing) {
          profileUser.followers.add(currentUser!.uid);
        } else {
          profileUser.followers.remove(currentUser!.uid);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isOwn = (widget.uid == currentUser!.uid);
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoaded) {
          final user = state.profileUserEntity;
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
                      // Refresh after returning
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
                    // Profile image and info
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
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                    ),
                                    Center(
                                      child: GestureDetector(
                                        onTap: () =>
                                            Navigator.of(context).pop(),
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
                          imageBuilder: (context, imageProvider) => Container(
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
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            child: const CupertinoActivityIndicator(),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 150,
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: Theme.of(context).colorScheme.secondary,
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
                    // Email
                    Text(
                      user.email,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // profile stats
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
                      postCount: postCount,
                      followersCount: user.followers.length,
                      followingCount: user.followings.length,
                    ),
                    const SizedBox(height: 25),
                    if (!isOwn)
                      FollowButton(
                        isFollowing: user.followers.contains(currentUser!.uid),
                        onTap: followButtonPressed,
                      ),
                    // Bio
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
                    // Posts list
                    BlocBuilder<PostCubit, PostState>(
                      builder: (context, state) {
                        if (state is PostLoaded) {
                          final userPosts = state.posts
                              .where((element) => element.userId == widget.uid)
                              .toList();
                          postCount = userPosts.length;
                          if (userPosts.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 32.0,
                              ),
                              child: Center(
                                child: Text(
                                  "No posts yet.",
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.inversePrimary,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: postCount,
                            itemBuilder: (context, index) {
                              final post = userPosts[index];
                              return PostTile(
                                post: post,
                                onDeletePressed: () => context
                                    .read<PostCubit>()
                                    .deletePost(post.id),
                              );
                            },
                          );
                        } else if (state is PostLoading) {
                          return const Center(
                            child: CupertinoActivityIndicator(),
                          );
                        } else if (state is PostError) {
                          return Center(child: Text(state.errMessage));
                        }
                        return const SizedBox();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (state is ProfileLoading || state is ProfileImageUploading) {
          return const Scaffold(
            body: Center(child: CupertinoActivityIndicator()),
          );
        } else if (state is ProfileError) {
          return Scaffold(
            body: Center(
              child: Text(
                state.errMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        } else {
          return const Scaffold(body: Center(child: Text("No Profile Loaded")));
        }
      },
    );
  }
}
