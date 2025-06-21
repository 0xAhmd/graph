import 'package:flutter/material.dart';
import 'package:ig_mate/features/comments/domain/entities/comment.dart';

class CommentDeleteDialog {
  static void show({
    required BuildContext context,
    required Comment comment,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Comment',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          comment.hasReplies
              ? 'This will delete the comment and all its replies. Are you sure?'
              : 'Are you sure you want to delete this comment?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
