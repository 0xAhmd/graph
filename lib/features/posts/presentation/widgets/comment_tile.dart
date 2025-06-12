import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../domain/entities/comment.dart';

class CommentTile extends StatefulWidget {
  const CommentTile({
    super.key,
    required this.comment,
    required this.currentUserId, // Add this to identify if user owns the comment
    this.onDeleteComment, // Callback for deleting comment
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

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwnComment) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit comment'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement edit functionality
                  Fluttertoast.showToast(
                    msg: "Feature still under construction",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.red, // or Colors.green, etc.
                    textColor: Colors.white,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete comment',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.report, color: Colors.orange),
                title: const Text('Report comment'),
                onTap: () {
                  Navigator.pop(context);
                  Fluttertoast.showToast(
                    msg: "Comment Reported",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.red, // or Colors.green, etc.
                    textColor: Colors.white,
                  );
                },
              ),
            ],
          ],
        ),
      ),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDeleteComment?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.comment.userName,
                          style: TextStyle(
                            color: theme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      // Three dots menu
                      GestureDetector(
                        onTap: _showOptionsMenu,
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
