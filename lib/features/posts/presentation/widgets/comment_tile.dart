import 'package:flutter/material.dart';
import '../../domain/entities/comment.dart';

class CommentTile extends StatefulWidget {
  const CommentTile({super.key, required this.comment});
  final Comment comment;

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool isExpanded = false;

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
          // Circle avatar with first letter of username
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.primary.withOpacity(0.2),
            child: Text(
              widget.comment.userName.isNotEmpty
                  ? widget.comment.userName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: theme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Comment bubble
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.comment.userName,
                    style: TextStyle(
                      color: theme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          text,
                          maxLines: isExpanded ? null : 1,
                          overflow: isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.onSurface,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (showSeeMore && !isExpanded)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              isExpanded = true;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            "See more",
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      if (showSeeMore && isExpanded)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              isExpanded = false;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            "See less",
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                    ],
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
