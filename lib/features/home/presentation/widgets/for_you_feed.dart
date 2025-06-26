import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'empty_messages.dart';

import '../../../posts/presentation/widgets/post_tile.dart';
import '../../../auth/presentation/cubit/cubit/auth_cubit.dart';
import '../../../profile/presentation/cubit/cubit/profile_cubit.dart';

class ForYouFeed extends StatelessWidget {
  final List<dynamic> posts;
  final Future<void> Function() onRefresh;
  final void Function(String postId) onDeletePost;
  final void Function(String userId) onBlockUser;
  final void Function(String userId) onUnblockUser;
  final VoidCallback onNavigateToDiscover;

  const ForYouFeed({
    super.key,
    required this.posts,
    required this.onRefresh,
    required this.onDeletePost,
    required this.onBlockUser,
    required this.onUnblockUser,
    required this.onNavigateToDiscover,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: EmptyFeedMessages.buildEmptyForYouMessage(
          context: context,
          onNavigateToDiscover: onNavigateToDiscover,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
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
        },
      ),
    );
  }
}