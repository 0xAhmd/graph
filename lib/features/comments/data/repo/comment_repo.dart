import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repo/comment_repo_interface.dart';
import '../../domain/entities/comment.dart';

class CommentRepo implements CommentRepoContract {
  final CollectionReference postCollection = FirebaseFirestore.instance
      .collection('posts');

  @override
  Future<List<Comment>> fetchCommentsByPostId(String postId) async {
    try {
      final postDoc = await postCollection.doc(postId).get();
      if (!postDoc.exists) return [];

      final data = postDoc.data() as Map<String, dynamic>;
      final commentsData = data['comments'] as List<dynamic>? ?? [];

      List<Comment> comments = [];

      for (var commentData in commentsData) {
        final commentMap = commentData as Map<String, dynamic>;
        final commenterId = commentMap['commenterId'] ?? commentMap['userId'];

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(commenterId)
            .get();

        String profileImageUrl = '';
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          profileImageUrl = userData['profileImgUrl'] as String? ?? '';
        }

        // Store it using the correct expected key for the Comment model
        commentMap['userProfileImageUrl'] = profileImageUrl;

        comments.add(Comment.fromJson(commentMap));
      }

      return comments;
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

        // If this is a reply, update parent's childCommentIds
        if (comment.parentCommentId != null) {
          final parentIndex = comments.indexWhere(
            (c) => c.id == comment.parentCommentId,
          );
          if (parentIndex != -1) {
            final parentComment = comments[parentIndex];
            final updatedChildIds = List<String>.from(
              parentComment.childCommentIds,
            )..add(comment.id);
            comments[parentIndex] = parentComment.copyWith(
              childCommentIds: updatedChildIds,
            );
          }
        }

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

        final commentToDelete = comments.firstWhere(
          (c) => c.id == commentId,
          orElse: () => throw Exception('Comment not found'),
        );

        // If deleting a parent comment, also delete all its children
        final commentsToDelete = <String>{commentId};
        _collectChildComments(comments, commentId, commentsToDelete);

        // Remove all comments that should be deleted
        comments.removeWhere((c) => commentsToDelete.contains(c.id));

        // If the deleted comment was a reply, remove it from parent's childCommentIds
        if (commentToDelete.parentCommentId != null) {
          final parentIndex = comments.indexWhere(
            (c) => c.id == commentToDelete.parentCommentId,
          );
          if (parentIndex != -1) {
            final parentComment = comments[parentIndex];
            final updatedChildIds = List<String>.from(
              parentComment.childCommentIds,
            )..remove(commentId);
            comments[parentIndex] = parentComment.copyWith(
              childCommentIds: updatedChildIds,
            );
          }
        }

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
    String newText, {
    bool? isMarkdown,
  }) async {
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
          final updatedComment = oldComment.copyWith(
            text: newText,
            timestamp: DateTime.now(),
            isMarkdown: isMarkdown ?? oldComment.isMarkdown,
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

  // Helper method to collect all child comments recursively
  void _collectChildComments(
    List<Comment> allComments,
    String parentId,
    Set<String> toDelete,
  ) {
    final children = allComments.where((c) => c.parentCommentId == parentId);
    for (final child in children) {
      toDelete.add(child.id);
      _collectChildComments(allComments, child.id, toDelete);
    }
  }

  // New method to add a reply to a specific comment
  @override
  Future<void> addReply(
    String postId,
    String parentCommentId,
    Comment reply,
  ) async {
    try {
      final postDoc = await postCollection.doc(postId).get();
      if (postDoc.exists) {
        final data = postDoc.data() as Map<String, dynamic>;
        final comments = (data['comments'] as List<dynamic>? ?? [])
            .map((e) => Comment.fromJson(e as Map<String, dynamic>))
            .toList();

        // Find parent comment to determine depth
        final parentComment = comments.firstWhere(
          (c) => c.id == parentCommentId,
          orElse: () => throw Exception('Parent comment not found'),
        );

        // Create reply with proper depth and parent reference
        final replyWithParent = reply.copyWith(
          parentCommentId: parentCommentId,
          depth: parentComment.depth + 1,
        );

        comments.add(replyWithParent);

        // Update parent's childCommentIds
        final parentIndex = comments.indexWhere((c) => c.id == parentCommentId);
        if (parentIndex != -1) {
          final updatedChildIds = List<String>.from(
            parentComment.childCommentIds,
          )..add(reply.id);
          comments[parentIndex] = parentComment.copyWith(
            childCommentIds: updatedChildIds,
          );
        }

        await postCollection.doc(postId).update({
          'comments': comments.map((c) => c.toJson()).toList(),
        });
      } else {
        throw Exception('Post not found');
      }
    } catch (e) {
      throw Exception("Error adding reply: $e");
    }
  }
}
