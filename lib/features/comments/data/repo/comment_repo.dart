import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ig_mate/features/comments/domain/repo/comment_repo_interface.dart';
import '../../domain/entities/comment.dart';

class CommentRepo implements CommentRepoContract {
  final CollectionReference postCollection = FirebaseFirestore.instance
      .collection('posts');

  @override
  Future<List<Comment>> fetchCommentsByPostId(String postId) async {
    try {
      final postDoc = await postCollection.doc(postId).get();
      if (postDoc.exists) {
        final data = postDoc.data() as Map<String, dynamic>;
        final commentsData = data['comments'] as List<dynamic>? ?? [];
        return commentsData
            .map(
              (commentData) =>
                  Comment.fromJson(commentData as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Error fetching comments: $e");
    }
  }

  @override
  Future<void> addComment(String postId, Comment comment) async {
    try {
      final postDoc = await postCollection.doc(postId).get();
      if (postDoc.exists) {
        final data = postDoc.data() as Map<String, dynamic>;
        final comments = (data['comments'] as List<dynamic>? ?? [])
            .map((e) => Comment.fromJson(e as Map<String, dynamic>))
            .toList();

        comments.add(comment);

        await postCollection.doc(postId).update({
          'comments': comments.map((c) => c.toJson()).toList(),
        });
      } else {
        throw Exception('Post not found');
      }
    } catch (e) {
      throw Exception("Error adding comment: $e");
    }
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      final postDoc = await postCollection.doc(postId).get();
      if (postDoc.exists) {
        final data = postDoc.data() as Map<String, dynamic>;
        final comments = (data['comments'] as List<dynamic>? ?? [])
            .map((e) => Comment.fromJson(e as Map<String, dynamic>))
            .toList();

        comments.removeWhere((comment) => comment.id == commentId);

        await postCollection.doc(postId).update({
          'comments': comments.map((c) => c.toJson()).toList(),
        });
      } else {
        throw Exception('Post not found');
      }
    } catch (e) {
      throw Exception("Error deleting comment: $e");
    }
  }

  @override
  Future<void> editComment(
    String postId,
    String commentId,
    String newText,
  ) async {
    try {
      final postDoc = await postCollection.doc(postId).get();
      if (postDoc.exists) {
        final data = postDoc.data() as Map<String, dynamic>;
        final comments = (data['comments'] as List<dynamic>? ?? [])
            .map((e) => Comment.fromJson(e as Map<String, dynamic>))
            .toList();

        final commentIndex = comments.indexWhere((c) => c.id == commentId);
        if (commentIndex != -1) {
          final oldComment = comments[commentIndex];
          final updatedComment = Comment(
            postId: postId,
            id: oldComment.id,
            userId: oldComment.userId,
            userName: oldComment.userName,
            text: newText,
            timestamp: DateTime.now(),
          );
          comments[commentIndex] = updatedComment;

          await postCollection.doc(postId).update({
            'comments': comments.map((c) => c.toJson()).toList(),
          });
        } else {
          throw Exception('Comment not found');
        }
      } else {
        throw Exception('Post not found');
      }
    } catch (e) {
      throw Exception("Error editing comment: $e");
    }
  }
}
