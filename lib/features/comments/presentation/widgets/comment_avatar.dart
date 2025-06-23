import 'package:flutter/material.dart';

class CommentAvatar extends StatelessWidget {
  final String userName;
  final String userId;
  final Color color;
  final VoidCallback? onTap;

  const CommentAvatar({
    super.key,
    required this.userName,
    required this.userId,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 18,
        backgroundColor: color.withOpacity(0.2),
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
