import 'package:flutter/material.dart';
import 'package:ig_mate/features/comments/domain/entities/comment.dart';
import 'package:ig_mate/features/comments/presentation/widgets/utils/comment_constants.dart';
import 'package:ig_mate/features/comments/presentation/widgets/utils/comment_helpers.dart';

class CommentHeader extends StatelessWidget {
  final Comment comment;
  final VoidCallback onOptionsPressed;

  const CommentHeader({
    super.key,
    required this.comment,
    required this.onOptionsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                comment.userName,
                style: TextStyle(
                  color: theme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: CommentConstants.usernameTextSize,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                CommentHelpers.formatTimestamp(comment.timestamp),
                style: TextStyle(
                  color: theme.onSurface.withOpacity(0.6),
                  fontSize: CommentConstants.timestampTextSize,
                ),
              ),
              if (comment.isMarkdown) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.text_format,
                  size: CommentConstants.markdownIconSize,
                  color: theme.primary.withOpacity(0.7),
                ),
              ],
            ],
          ),
        ),
        GestureDetector(
          onTap: onOptionsPressed,
          child: Icon(
            Icons.more_vert,
            size: CommentConstants.optionsIconSize,
            color: theme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
