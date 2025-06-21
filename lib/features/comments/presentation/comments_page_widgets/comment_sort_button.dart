import 'package:flutter/material.dart';

class CommentSortButton extends StatelessWidget {
  final String sortBy;
  final ValueChanged<String> onSortChanged;

  const CommentSortButton({
    super.key,
    required this.sortBy,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.sort,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
      onSelected: onSortChanged,
      itemBuilder: (context) => [
        _buildSortMenuItem(
          context,
          'newest',
          'Newest First',
          Icons.access_time,
        ),
        _buildSortMenuItem(context, 'oldest', 'Oldest First', Icons.history),
        _buildSortMenuItem(
          context,
          'most_replies',
          'Most Replies',
          Icons.forum,
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = sortBy == value;
    final theme = Theme.of(context);

    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
