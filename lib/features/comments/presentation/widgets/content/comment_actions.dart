import 'package:flutter/material.dart';
import '../../../domain/entities/comment.dart';
import '../utils/comment_constants.dart';

class CommentActions extends StatelessWidget {
  final Comment comment;
  final List<Comment>? replies;
  final bool isReplying;
  final bool showReplies;
  final VoidCallback onReplyPressed;
  final VoidCallback? onRepliesPressed;

  const CommentActions({
    super.key,
    required this.comment,
    this.replies,
    required this.isReplying,
    required this.showReplies,
    required this.onReplyPressed,
    this.onRepliesPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Reply button
        if (comment.canHaveReplies)
          TextButton.icon(
            onPressed: onReplyPressed,
            icon: Icon(
              isReplying ? Icons.close : Icons.reply,
              size: CommentConstants.actionIconSize,
            ),
            label: Text(
              isReplying ? 'Cancel' : 'Reply',
              style: const TextStyle(fontSize: CommentConstants.actionTextSize),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
            ),
          ),

        // Replies button
        if (comment.hasReplies && replies != null && replies!.isNotEmpty)
          TextButton.icon(
            onPressed: onRepliesPressed,
            icon: Icon(
              showReplies ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: CommentConstants.actionIconSize,
            ),
            label: Text(
              showReplies 
                ? 'Hide replies' 
                : '${replies!.length} ${replies!.length == 1 ? 'reply' : 'replies'}',
              style: const TextStyle(fontSize: CommentConstants.actionTextSize),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
            ),
          ),
      ],
    );
  }
}