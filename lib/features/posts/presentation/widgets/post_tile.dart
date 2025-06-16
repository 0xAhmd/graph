// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/index.dart';
import '../pages/comments_page.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/cubit/cubit/auth_cubit.dart';
import '../../domain/entities/post_entity.dart';
import '../cubit/post_cubit.dart';

import '../../../profile/domain/entities/profile_user.dart';
import '../../../profile/presentation/cubit/cubit/profile_cubit.dart';

class PostTile extends StatefulWidget {
  const PostTile({
    super.key,
    required this.post,
    required this.onDeletePressed,
    this.onBlockPressed,
    this.onUnblockPressed,
    this.isUserBlocked = false,
  });

  final Post post;
  final void Function()? onDeletePressed;
  final void Function()? onBlockPressed;
  final void Function()? onUnblockPressed;
  final bool isUserBlocked;

  @override
  State<PostTile> createState() => _PostTileState();
}

class _PostTileState extends State<PostTile> {
  late final postCubit = context.read<PostCubit>();
  late final profileCubit = context.read<ProfileCubit>();
  AppUser? currentUser;
  bool isOwnPost = false;
  ProfileUserEntity? postUser;
  bool isCaptionExpanded = false;

  @override
  void initState() {
    getCurrentUser();
    fetchPostUser();
    super.initState();
  }

  void getCurrentUser() {
    final autCubit = context.read<AuthCubit>();
    currentUser = autCubit.currentUser;
    isOwnPost = (widget.post.userId == currentUser!.uid);
  }

  Future<void> fetchPostUser() async {
    final fetchedUser = await profileCubit.getUserProfile(widget.post.userId);
    if (fetchedUser != null && mounted) {
      setState(() {
        postUser = fetchedUser;
      });
    }
  }

  void openCommentsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CommentsPage(post: widget.post)),
    );
  }

  bool showHeart = false;
  void like() {
    final isLiked = widget.post.likes.contains(currentUser!.uid);
    setState(() {
      if (isLiked) {
        widget.post.likes.remove(currentUser!.uid);
      } else {
        widget.post.likes.add(currentUser!.uid);
      }
      showHeart = true;
    });

    // Hide the heart after a short delay
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          showHeart = false;
        });
      }
    });

    postCubit.toggleLikes(widget.post.id, currentUser!.uid).catchError((error) {
      setState(() {
        if (isLiked) {
          widget.post.likes.add(currentUser!.uid);
        } else {
          widget.post.likes.remove(currentUser!.uid);
        }
      });
    });
  }

  Widget _buildLatestComment(Post currentPost) {
    if (currentPost.comments.isEmpty) {
      return const SizedBox();
    }

    // Get the latest comment (last in the list)
    final latestComment = currentPost.comments.last;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: openCommentsPage,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Comment avatar with shadow
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      latestComment.userName.isNotEmpty
                          ? latestComment.userName[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Comment content with better typography
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: latestComment.userName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                letterSpacing: 0.1,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '  ${latestComment.text.length > 60 ? '${latestComment.text.substring(0, 60)}...' : latestComment.text}',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.85),
                                fontSize: 14,
                                height: 1.3,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Time indicator
                      Text(
                        _getTimeAgo(latestComment.timestamp),
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow indicator
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.secondary,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: PostHeader(
              onDeletePressed: widget.onDeletePressed,
              post: widget.post,
              postUser: postUser,
              isOwnPost: isOwnPost,
              isUserBlocked: widget.isUserBlocked,
              onBlockPressed: widget.onBlockPressed,
              onUnblockPressed: widget.onUnblockPressed,
            ),
          ),

          PostImage(
            imageUrl: widget.post.imageUrl,
            onDoubleTap: like,
            showHeart: showHeart,
            isLiked: widget.post.likes.contains(currentUser!.uid),
          ),

          // buttons + time
          PostActions(
            post: widget.post,
            isLiked: widget.post.likes.contains(currentUser!.uid),
            likeCount: widget.post.likes.length,
            commentCount: widget.post.comments.length,
            onLike: like,
            onComment:
                openCommentsPage, // Navigate to comments page instead of opening modal
            timeStamp: widget.post.timeStamp,
          ),

          PostCaption(
            userName: widget.post.userName,
            text: widget.post.text,
            isExpanded: isCaptionExpanded,
            onToggleExpand: () {
              setState(() {
                isCaptionExpanded = !isCaptionExpanded;
              });
            },
          ),
          const SizedBox(height: 15),
          // Show latest comment only
          BlocBuilder<PostCubit, PostState>(
            builder: (context, state) {
              if (state is PostLoaded) {
                final currentPost = state.posts.firstWhere(
                  (post) => post.id == widget.post.id,
                  orElse: () => widget.post,
                );

                return _buildLatestComment(currentPost);
              }
              return const SizedBox();
            },
          ),

          // View all comments button (if there are comments)
          BlocBuilder<PostCubit, PostState>(
            builder: (context, state) {
              if (state is PostLoaded) {
                final currentPost = state.posts.firstWhere(
                  (post) => post.id == widget.post.id,
                  orElse: () => widget.post,
                );

                if (currentPost.comments.isNotEmpty) {
                  return GestureDetector(
                    onTap: openCommentsPage,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        currentPost.comments.length == 1
                            ? 'View comment'
                            : 'View all ${currentPost.comments.length} comments',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }
              }
              return const SizedBox();
            },
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
