import 'package:flutter/material.dart';

import '../../domain/entities/comment.dart';
import 'comment_sort_button.dart';

class CommentStatsHeader extends StatelessWidget {
  final List<Comment> comments;
  final String sortBy;
  final ValueChanged<String> onSortChanged;

  const CommentStatsHeader({
    super.key,
    required this.comments,
    required this.sortBy,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rootComments = comments.where((c) => c.isRootComment).length;
    final totalComments = comments.length;
    final repliesCount = totalComments - rootComments;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.comment_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 8),
          Text(
            '$rootComments ${rootComments == 1 ? 'comment' : 'comments'}',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (repliesCount > 0) ...[
            const SizedBox(width: 16),
            Icon(
              Icons.reply,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            Text(
              '$repliesCount ${repliesCount == 1 ? 'reply' : 'replies'}',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const Spacer(),
          CommentSortButton(
            sortBy: sortBy,
            onSortChanged: onSortChanged,
          ),
        ],
      ),
    );
  }
}