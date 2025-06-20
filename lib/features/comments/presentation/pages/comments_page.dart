import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ig_mate/features/comments/presentation/widgets/comment_tile.dart';
import '../../../../core/utils/text_bomb_detector.dart';
import '../../../../layout/constrained_scaffold.dart';

import '../../domain/entities/comment.dart';
import '../cubit/comment_cubit.dart';
import '../../../auth/presentation/cubit/cubit/auth_cubit.dart';
import '../../../auth/domain/entities/app_user.dart';

class CommentsPage extends StatefulWidget {
  final String postId;
  final String postUserId; // Optional: if you want to show post owner info

  const CommentsPage({
    super.key,
    required this.postId,
    required this.postUserId,
  });

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final CommentCubit commentCubit;
  AppUser? currentUser;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    commentCubit = context.read<CommentCubit>();
    currentUser = context.read<AuthCubit>().currentUser;
    // Fetch comments when page loads
    commentCubit.fetchComments(widget.postId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _postComment() async {
    final commentText = _commentController.text.trim();

    if (commentText.isEmpty) {
      Fluttertoast.showToast(
        msg: "Comment cannot be empty",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    if (isTextBomb(commentText)) {
      Fluttertoast.showToast(
        msg: "Comment contains inappropriate content",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    final newComment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: widget.postId,
      userId: currentUser!.uid,
      userName: currentUser!.name,
      text: commentText,
      timestamp: DateTime.now(),
    );

    try {
      await commentCubit.addComment(widget.postId, newComment);
      _commentController.clear();
      _focusNode.unfocus();

      Fluttertoast.showToast(
        msg: "Comment posted successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to post comment",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }

  void _deleteComment(String commentId) {
    commentCubit.deleteComment(widget.postId, commentId);
  }

  void _editComment(String commentId, String newText) {
    commentCubit.editComment(widget.postId, commentId, newText);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedScaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Comments list
          Expanded(
            child: BlocConsumer<CommentCubit, CommentState>(
              listener: (context, state) {
                if (state is CommentError) {
                  Fluttertoast.showToast(
                    msg: state.errMessage,
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                }
              },
              builder: (context, state) {
                if (state is CommentLoading) {
                  return const Center(child: CupertinoActivityIndicator());
                } else if (state is CommentLoaded) {
                  if (state.comments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No comments yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to comment!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.comments.length,
                    itemBuilder: (context, index) {
                      final comment = state.comments[index];
                      return CommentTile(
                        comment: comment,
                        currentUserId: currentUser!.uid,
                        onDeleteComment: () => _deleteComment(comment.id),
                        onEditComment: _editComment,
                      );
                    },
                  );
                } else if (state is CommentError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading comments',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.errMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              commentCubit.fetchComments(widget.postId),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),

          // Comment input section
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Text field
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      focusNode: _focusNode,
                      maxLines: null,
                      maxLength: 700,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        counterText: '', // Hide character counter
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Post button
                  GestureDetector(
                    onTap: _isPosting ? null : _postComment,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            _commentController.text.trim().isNotEmpty &&
                                !_isPosting
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: _isPosting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.send,
                              size: 18,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
