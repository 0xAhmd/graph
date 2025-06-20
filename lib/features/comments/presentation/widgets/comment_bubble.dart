import 'package:flutter/material.dart';

class CommentBubble extends StatelessWidget {
  final String userName;
  final String text;
  final bool isExpanded;
  final bool showSeeMore;
  final VoidCallback onSeeMore;
  final VoidCallback onSeeLess;
  final VoidCallback onMenuTap;

  const CommentBubble({
    super.key,
    required this.userName,
    required this.text,
    required this.isExpanded,
    required this.showSeeMore,
    required this.onSeeMore,
    required this.onSeeLess,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  userName,
                  style: TextStyle(
                    color: theme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onMenuTap,
                child: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: theme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
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
                  onPressed: onSeeMore,
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
                  onPressed: onSeeLess,
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
    );
  }
}