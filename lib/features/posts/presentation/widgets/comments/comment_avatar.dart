import 'package:flutter/material.dart';

class CommentAvatar extends StatelessWidget {
  final String userName;
  final Color color;

  const CommentAvatar({super.key, required this.userName, required this.color});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
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
    );
  }
}