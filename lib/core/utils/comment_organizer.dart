import 'package:ig_mate/features/comments/domain/entities/comment.dart';

Map<String, List<Comment>> organizeComments(List<Comment> allComments) {
  final Map<String, List<Comment>> repliesMap = {};

  // Group replies by parent comment ID
  for (final comment in allComments) {
    if (comment.parentCommentId != null) {
      if (repliesMap[comment.parentCommentId!] == null) {
        repliesMap[comment.parentCommentId!] = [];
      }
      repliesMap[comment.parentCommentId!]!.add(comment);
    }
  }

  // Sort replies by timestamp (oldest first)
  repliesMap.forEach((key, replies) {
    replies.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  });

  return repliesMap;
}

// Get only parent comments (top-level comments)
List<Comment> getParentComments(List<Comment> allComments) {
  return allComments
      .where((comment) => comment.parentCommentId == null)
      .toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp)); // Sort by timestamp
}
