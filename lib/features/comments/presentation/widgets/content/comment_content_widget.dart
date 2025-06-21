import 'package:flutter/material.dart';
import 'package:ig_mate/features/comments/domain/entities/comment.dart';
import 'package:ig_mate/features/comments/presentation/widgets/utils/comment_constants.dart';
import 'comment_header.dart';
import 'comment_text_display.dart';
import 'comment_actions.dart';

class CommentContentWidget extends StatelessWidget {
  final Comment comment;
  final List<Comment>? replies;
  final bool isReplying;
  final bool showReplies;
  final VoidCallback onOptionsPressed;
  final VoidCallback onReplyPressed;
  final VoidCallback? onRepliesPressed;

  const CommentContentWidget({
    super.key,
    required this.comment,
    this.replies,
    required this.isReplying,
    required this.showReplies,
    required this.onOptionsPressed,
    required this.onReplyPressed,
    this.onRepliesPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Container(
      padding: CommentConstants.contentContainerPadding,
      decoration: BoxDecoration(
        color: theme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: CommentConstants.commentBorderRadiusGeometry,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          CommentHeader(
            comment: comment,
            onOptionsPressed: onOptionsPressed,
          ),
          const SizedBox(height: 6),

          // Content
          CommentTextDisplay(comment: comment),

          // Action buttons
          const SizedBox(height: 4),
          CommentActions(
            comment: comment,
            replies: replies,
            isReplying: isReplying,
            showReplies: showReplies,
            onReplyPressed: onReplyPressed,
            onRepliesPressed: onRepliesPressed,
          ),
        ],
      ),
    );
  }
}