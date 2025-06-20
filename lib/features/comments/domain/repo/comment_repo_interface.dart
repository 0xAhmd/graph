import '../entities/comment.dart';

abstract class CommentRepoContract {
  Future<List<Comment>> fetchCommentsByPostId(String postId);
  Future<void> addComment(String postId, Comment comment);
  Future<void> deleteComment(String postId, String commentId);
  Future<void> editComment(
    String postId, 
    String commentId, 
    String newText, {
    bool? isMarkdown,
  });
  Future<void> addReply(String postId, String parentCommentId, Comment reply);
}