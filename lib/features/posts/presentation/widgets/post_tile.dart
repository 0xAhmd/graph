// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/index.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/cubit/cubit/auth_cubit.dart';
import '../../domain/entities/comment.dart';
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

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
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

  final TextEditingController commentController = TextEditingController();

  void openCommentBox() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CustomBottomSheet(
        controller: commentController,
        onPost: (commentText) {
          comment();
        },
        title: 'New Comment',
        hintText: 'Add a comment...',
        buttonLabel: 'POST',
      ),
    );
  }

  void comment() {
    final newComment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: widget.post.id,
      userId: currentUser!.uid,
      userName: currentUser!.name,
      text: commentController.text,
      timestamp: DateTime.now(),
    );
    if (commentController.text.isNotEmpty) {
      postCubit.addComment(widget.post.id, newComment);
      commentController.clear();
    }
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
              post: widget.post,
              postUser: postUser,
              isOwnPost: isOwnPost,
              isUserBlocked: widget.isUserBlocked,
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
            onComment: openCommentBox,
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

          const SizedBox(height: 6),
          BlocBuilder<PostCubit, PostState>(
            builder: (context, state) {
              if (state is PostLoaded) {
                final currentPost = state.posts.firstWhere(
                  (post) => post.id == widget.post.id,
                  orElse: () => widget.post,
                );

                if (currentPost.comments.isNotEmpty) {
                  int showCommentsCount = currentPost.comments.length;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: showCommentsCount,
                    itemBuilder: (context, index) {
                      final comment = currentPost.comments[index];
                      return CommentTile(
                        comment: comment,
                        onDeleteComment: () {
                          postCubit.deleteComment(widget.post.id, comment.id);
                        },
                        currentUserId: currentUser!.uid,
                      );
                    },
                  );
                }
                // If there are no comments, you can return an empty SizedBox or a message
                return const SizedBox();
              } else if (state is PostLoading) {
                return const Center(child: CupertinoActivityIndicator());
              } else if (state is PostError) {
                return Center(child: Text(state.errMessage));
              } else {
                return Center(
                  child: Text(
                    'Something went wrong',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
