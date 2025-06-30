// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/features/comments/presentation/widgets/comment_avatar.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/cubit/cubit/auth_cubit.dart';
import '../../../comments/domain/entities/comment.dart';
import '../../../comments/presentation/cubit/comment_cubit.dart';
import '../../../comments/presentation/pages/comments_page.dart';
import '../../../profile/domain/entities/profile_user.dart';
import '../../../profile/presentation/cubit/cubit/profile_cubit.dart';
import '../../domain/entities/post_entity.dart';
import '../cubit/post_cubit.dart';
import '../widgets/index.dart';

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
  late final commentCubit = context.read<CommentCubit>();

  AppUser? currentUser;
  bool isOwnPost = false;
  ProfileUserEntity? postUser;
  bool isCaptionExpanded = false;
  List<Comment> postComments = [];
  int commentCount = 0;
  bool commentsLoaded = false;

  @override
  void initState() {
    getCurrentUser();
    fetchPostUser();
    loadComments();
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

  Future<void> loadComments() async {
    if (commentsLoaded) return;

    try {
      final cached = commentCubit.getCommentsForPost(widget.post.id);
      if (cached.isNotEmpty) {
        setState(() {
          postComments = cached;
          commentCount = cached.length;
          commentsLoaded = true;
        });
        return;
      }

      await commentCubit.fetchComments(widget.post.id);

      final currentState = commentCubit.state;
      if (currentState is CommentLoaded) {
        final commentsForThisPost = currentState.getCommentsForPost(
          widget.post.id,
        );
        setState(() {
          postComments = commentsForThisPost;
          commentCount = commentsForThisPost.length;
          commentsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> reloadComments() async {
    if (!mounted) return; // Add this check

    setState(() {
      commentsLoaded = false;
    });
    await loadComments();
  }

  void openCommentsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsPage(
          postId: widget.post.id,
          postUserId: widget.post.userId,
        ),
      ),
    ).then((_) {
      reloadComments();
    });
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

  Widget _buildLatestComment(List<Comment> comments) {
    // Filter out comments from blocked users
    final filteredComments = comments
        .where((comment) => !profileCubit.isUserBlocked(comment.userId))
        .toList();

    if (filteredComments.isEmpty) {
      return const SizedBox();
    }

    // Get the latest comment (last in the filtered list)
    final latestComment = filteredComments.last;

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
                  child: CommentAvatar(
                    userName: latestComment.userName,
                    userId: latestComment.userId,
                    profileImageUrl: latestComment.userProfileImageUrl,
                    color: Theme.of(context).colorScheme.primary,
                    onTap: openCommentsPage,
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

  Widget _buildViewCommentsButton(int commentCount) {
    if (commentCount == 0) {
      return const SizedBox();
    }

    return GestureDetector(
      onTap: openCommentsPage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          commentCount == 1
              ? 'View comment'
              : 'View all $commentCount comments',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 13,
            fontWeight: FontWeight.w500,
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
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

          // Listen to comment state changes
          BlocListener<CommentCubit, CommentState>(
            listener: (context, state) {
              if (state is CommentLoaded &&
                  state.commentsByPost.containsKey(widget.post.id)) {
                final commentsForThisPost = state.getCommentsForPost(
                  widget.post.id,
                );
                setState(() {
                  postComments = commentsForThisPost;
                  commentCount = commentsForThisPost.length;
                  commentsLoaded = true;
                });
              }
            },
            child: Column(
              children: [
                // buttons + time
                PostActions(
                  post: widget.post,
                  isLiked: widget.post.likes.contains(currentUser!.uid),
                  likeCount: widget.post.likes.length,
                  commentCount: commentCount, // Use local state
                  onLike: like,
                  onComment: openCommentsPage,
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

                // Show latest comment using local state
                _buildLatestComment(postComments),

                // View all comments button using local state
                _buildViewCommentsButton(commentCount),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
