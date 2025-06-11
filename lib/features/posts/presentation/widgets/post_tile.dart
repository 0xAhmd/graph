import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/cubit/cubit/auth_cubit.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/post_entity.dart';
import '../cubit/post_cubit.dart';
import 'comment_tile.dart';
import 'custom_bottom_sheet.dart';
import '../../../profile/domain/entities/profile_user.dart';
import '../../../profile/presentation/cubit/cubit/profile_cubit.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import 'package:intl/intl.dart';

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

  void showOptions() {
    if (isOwnPost) {
      // Show delete dialog for own posts
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            "Delete Post ?",
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (widget.onDeletePressed != null) {
                  widget.onDeletePressed!();
                }
                Navigator.of(context).pop();
              },
              child: Text(
                "Delete",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Show block/unblock options for other users
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              if (!widget.isUserBlocked)
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: Text(
                    'Block ${widget.post.userName}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onBlockPressed != null) {
                      widget.onBlockPressed!();
                    }
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.green),
                  title: Text(
                    'Unblock ${widget.post.userName}',
                    style: const TextStyle(color: Colors.green),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onUnblockPressed != null) {
                      widget.onUnblockPressed!();
                    }
                  },
                ),
              ListTile(
                leading: Icon(
                  Icons.cancel,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                title: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                postUser?.profileImgUrl != null
                    ? GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfilePage(uid: widget.post.userId),
                            ),
                          );
                        },
                        child: CachedNetworkImage(
                          imageBuilder: (context, imageProvider) => Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          imageUrl: postUser!.profileImgUrl,
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.person),
                        ),
                      )
                    : const Icon(Icons.person),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfilePage(uid: widget.post.userId),
                      ),
                    );
                  },
                  child: Text(
                    widget.post.userName,
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                ),
                // Show blocked indicator
                if (widget.isUserBlocked)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'Blocked',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: showOptions,
                  child: Icon(
                    isOwnPost ? Icons.delete : Icons.more_vert,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onDoubleTap: like,
                child: CachedNetworkImage(
                  imageUrl: widget.post.imageUrl,
                  height: 450,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const SizedBox(height: 450),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error_outline),
                ),
              ),
              AnimatedOpacity(
                opacity: showHeart ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedScale(
                  scale: showHeart ? 1.6 : 0.5,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.favorite,
                    color: widget.post.likes.contains(currentUser!.uid)
                        ? Colors.redAccent
                        : Colors.white,
                    size: 120,
                    shadows: const [
                      Shadow(
                        blurRadius: 20,
                        color: Colors.black54,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // buttons + time
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                SizedBox(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: like,
                        child: Icon(
                          widget.post.likes.contains(currentUser!.uid)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: widget.post.likes.contains(currentUser!.uid)
                              ? Colors.red
                              : Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.post.likes.length.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: openCommentBox,
                  child: const Icon(Icons.comment),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.post.comments.length.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat(
                    'MMM d, yyyy • h:mm a',
                  ).format(widget.post.timeStamp),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ],
            ),
          ),

          // caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  widget.post.userName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.post.text,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ],
            ),
          ),

          // ...existing code above...
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
                      return CommentTile(comment: comment);
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
