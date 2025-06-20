// Update your comment_state.dart
part of 'comment_cubit.dart';

@immutable
sealed class CommentState {}

final class CommentInitial extends CommentState {}

final class CommentLoading extends CommentState {
  final String postId;
  CommentLoading({required this.postId});
}

final class CommentLoaded extends CommentState {
  // Store comments per post ID
  final Map<String, List<Comment>> commentsByPost;

  CommentLoaded({required this.commentsByPost});

  // Helper method to get comments for a specific post
  List<Comment> getCommentsForPost(String postId) {
    return commentsByPost[postId] ?? [];
  }
}

final class CommentError extends CommentState {
  final String errMessage;
  final String postId;

  CommentError({required this.errMessage, required this.postId});
}
