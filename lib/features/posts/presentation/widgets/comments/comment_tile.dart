import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:ig_mate/core/utils/text_bomb_detector.dart';

import 'package:ig_mate/features/posts/domain/entities/comment.dart';
import 'package:ig_mate/features/posts/presentation/cubit/post_cubit.dart';

import 'comment_avatar.dart';
import 'comment_bubble.dart';
import 'comment_menu.dart';

class CommentTile extends StatefulWidget {
  const CommentTile({
    super.key,
    required this.comment,
    required this.currentUserId,
    this.onDeleteComment,
  });

  final Comment comment;
  final String currentUserId;
  final VoidCallback? onDeleteComment;

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool isExpanded = false;

  bool get isOwnComment => widget.comment.userId == widget.currentUserId;

  void _showEditCommentDialog() {
    final TextEditingController controller = TextEditingController(
      text: widget.comment.text,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Edit Comment',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Text field
              TextField(
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                controller: controller,
                maxLines: null,
                minLines: 2,
                maxLength: 700, // Adjust as needed
                decoration: InputDecoration(
                  hintText: 'Edit your comment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _handleEditComment(controller.text.trim()),
                    child: const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _handleEditComment(String newText) {
    // Validate input
    if (newText.isEmpty) {
      Fluttertoast.showToast(
        msg: "Comment cannot be empty",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    // Check for text bomb (replace with your actual isTextBomb function)
    if (isTextBomb(newText)) {
      Fluttertoast.showToast(
        msg: "Comment contains inappropriate content",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    // Check if text is the same as original
    if (newText == widget.comment.text) {
      Navigator.pop(context);
      return;
    }

    // Close the bottom sheet
    Navigator.pop(context);

    // Call the cubit method to edit comment
    // Replace 'postCubit' with your actual cubit instance
    context.read<PostCubit>().editComment(
      widget.comment.postId,
      widget.comment.id,
      newText,
    );

    // Show success message
    Fluttertoast.showToast(
      msg: "Comment updated successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Comment',
          style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
        ),
        content: Text(
          'Are you sure you want to delete this comment?',
          style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Call the cubit to delete the comment
              context.read<PostCubit>().deleteComment(
                widget.comment.postId,
                widget.comment.id,
              );
              // Optionally call the callback
              if (widget.onDeleteComment != null) {
                widget.onDeleteComment!();
              }
              Fluttertoast.showToast(
                msg: "Comment deleted",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.green,
                textColor: Colors.white,
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: CommentMenu(
          isOwnComment: isOwnComment,
          onEdit: () {
            Navigator.pop(context);
            _showEditCommentDialog();
          },
          onDelete: () {
            Navigator.pop(context);
            _showDeleteConfirmation();
          },
          onReport: () {
            Navigator.pop(context);
            Fluttertoast.showToast(
              msg: "Comment Reported",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final text = widget.comment.text;
    final showSeeMore = text.length > 40 || text.split('\n').length > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommentAvatar(
            userName: widget.comment.userName,
            color: theme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CommentBubble(
              userName: widget.comment.userName,
              text: text,
              isExpanded: isExpanded,
              showSeeMore: showSeeMore,
              onSeeMore: () => setState(() => isExpanded = true),
              onSeeLess: () => setState(() => isExpanded = false),
              onMenuTap: _showOptionsMenu,
            ),
          ),
        ],
      ),
    );
  }
}
