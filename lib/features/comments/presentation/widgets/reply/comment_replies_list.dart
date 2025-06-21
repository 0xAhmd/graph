import 'package:flutter/material.dart';
import 'package:ig_mate/features/comments/domain/entities/comment.dart';
import '../comment_tile.dart';

class CommentRepliesList extends StatelessWidget {
  final List<Comment>? replies;
  final Animation<double> animation;
  final String currentUserId;
  final VoidCallback onDeleteComment;
  final Function(String commentId, String newText)? onEditComment;

  const CommentRepliesList({
    super.key,
    this.replies,
    required this.animation,
    required this.currentUserId,
    required this.onDeleteComment,
    this.onEditComment,
  });

  @override
  Widget build(BuildContext context) {
    if (replies == null || replies!.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizeTransition(
      sizeFactor: animation,
      child: Column(
        children: replies!.map((reply) {
          return CommentTile(
            comment: reply,
            currentUserId: currentUserId,
            onDeleteComment: onDeleteComment,
            onEditComment: onEditComment,
            showReplies: false, // Don't show nested replies by default
          );
        }).toList(),
      ),
    );
  }
}
