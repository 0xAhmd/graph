import 'package:flutter/material.dart';

class CommentMenu extends StatelessWidget {
  final bool isOwnComment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  const CommentMenu({
    super.key,
    required this.isOwnComment,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isOwnComment) ...[
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(
              'Edit comment',
              style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            onTap: onEdit,
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Delete comment',
              style: TextStyle(color: Colors.red),
            ),
            onTap: onDelete,
          ),
        ] else ...[
          ListTile(
            leading: const Icon(Icons.report, color: Colors.orange),
            title: const Text('Report comment'),
            onTap: onReport,
          ),
        ],
      ],
    );
  }
}
