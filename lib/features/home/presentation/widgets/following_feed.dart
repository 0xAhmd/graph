import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/features/home/presentation/widgets/empty_messages.dart';
import 'package:ig_mate/features/home/presentation/widgets/stories_section.dart';

import '../../../posts/presentation/widgets/post_tile.dart';
import '../../../auth/presentation/cubit/cubit/auth_cubit.dart';
import '../../../profile/presentation/cubit/cubit/profile_cubit.dart';


class FollowingFeed extends StatelessWidget {
  final List<dynamic> posts;
  final List<String> followingUserIds;
  final String? currentUserProfileImage;
  final Future<void> Function() onRefresh;
  final void Function(String postId) onDeletePost;
  final void Function(String userId) onBlockUser;
  final void Function(String userId) onUnblockUser;
  final VoidCallback onNavigateToSearch;

  const FollowingFeed({
    super.key,
    required this.posts,
    required this.followingUserIds,
    required this.currentUserProfileImage,
    required this.onRefresh,
    required this.onDeletePost,
    required this.onBlockUser,
    required this.onUnblockUser,
    required this.onNavigateToSearch,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 10),
          StoriesSection(
            followingUserIds: followingUserIds,
            currentUserProfileImage: currentUserProfileImage,
          ),
          const SizedBox(height: 8),
          if (posts.isEmpty)
            EmptyFeedMessages.buildEmptyFollowingMessage(
              context: context,
              onNavigateToSearch: onNavigateToSearch,
            )
          else
            ...posts.map((post) {
              final currentUser = context.read<AuthCubit>().currentUser;
              final profileCubit = context.read<ProfileCubit>();
              final isCurrentUserPost = currentUser?.uid == post.userId;
              final isUserBlocked = profileCubit.isUserBlocked(post.userId);

              return PostTile(
                key: ValueKey(post.id),
                post: post,
                onDeletePressed: () => onDeletePost(post.id),
                onBlockPressed: isCurrentUserPost
                    ? null
                    : () => onBlockUser(post.userId),
                onUnblockPressed: isCurrentUserPost
                    ? null
                    : () => onUnblockUser(post.userId),
                isUserBlocked: isUserBlocked,
              );
            }),
        ],
      ),
    );
  }
}