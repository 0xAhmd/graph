import 'package:bloc/bloc.dart';
import 'package:ig_mate/features/comments/domain/repo/comment_repo_interface.dart';
import 'package:meta/meta.dart';
import '../../domain/entities/comment.dart';

part 'comment_state.dart';

class CommentCubit extends Cubit<CommentState> {
  final CommentRepoContract commentRepo;

  CommentCubit({required this.commentRepo}) : super(CommentInitial());

  Future<void> fetchComments(String postId) async {
    final currentState = state;
    Map<String, List<Comment>> currentComments = {};

    // If we already have comments loaded, preserve them
    if (currentState is CommentLoaded) {
      currentComments = Map.from(currentState.commentsByPost);
      // If we already have comments for this post, don't show loading
      if (currentComments.containsKey(postId)) {
        return;
      }
    }

    // Show loading only if we don't already have comments for this post
    emit(CommentLoading(postId: postId));

    try {
      final comments = await commentRepo.fetchCommentsByPostId(postId);
      final organizedComments = _organizeComments(comments);
      currentComments[postId] = organizedComments;
      emit(CommentLoaded(commentsByPost: currentComments));
    } catch (e) {
      emit(
        CommentError(errMessage: "Failed to load comments: $e", postId: postId),
      );
    }
  }

  Future<void> addComment(String postId, Comment comment) async {
    final currentState = state;
    if (currentState is CommentLoaded) {
      final currentComments = Map<String, List<Comment>>.from(
        currentState.commentsByPost,
      );
      final postComments = List<Comment>.from(currentComments[postId] ?? []);

      // Optimistic update
      postComments.add(comment);
      final organizedComments = _organizeComments(postComments);
      currentComments[postId] = organizedComments;
      emit(CommentLoaded(commentsByPost: currentComments));

      try {
        await commentRepo.addComment(postId, comment);
      } catch (e) {
        // Revert on error - remove the comment we just added
        postComments.removeLast();
        final revertedComments = _organizeComments(postComments);
        currentComments[postId] = revertedComments;
        emit(CommentLoaded(commentsByPost: currentComments));
        emit(CommentError(errMessage: e.toString(), postId: postId));
      }
    } else {
      // If no comments are loaded yet, we need to fetch them first
      await fetchComments(postId);
      // Try adding the comment again after fetching
      if (state is CommentLoaded) {
        await addComment(postId, comment);
      }
    }
  }

  Future<void> addReply(
    String postId,
    String parentCommentId,
    Comment reply,
  ) async {
    final currentState = state;
    if (currentState is CommentLoaded) {
      final currentComments = Map<String, List<Comment>>.from(
        currentState.commentsByPost,
      );
      final postComments = List<Comment>.from(currentComments[postId] ?? []);

      // Find parent comment to set proper depth
      final parentComment = postComments.firstWhere(
        (c) => c.id == parentCommentId,
        orElse: () => throw Exception('Parent comment not found'),
      );

      // Create reply with proper nesting
      final replyWithParent = reply.copyWith(
        parentCommentId: parentCommentId,
        depth: parentComment.depth + 1,
      );

      // Optimistic update
      postComments.add(replyWithParent);

      // Update parent's child IDs
      final parentIndex = postComments.indexWhere(
        (c) => c.id == parentCommentId,
      );
      if (parentIndex != -1) {
        final updatedChildIds = List<String>.from(parentComment.childCommentIds)
          ..add(reply.id);
        postComments[parentIndex] = parentComment.copyWith(
          childCommentIds: updatedChildIds,
        );
      }

      final organizedComments = _organizeComments(postComments);
      currentComments[postId] = organizedComments;
      emit(CommentLoaded(commentsByPost: currentComments));

      try {
        await commentRepo.addReply(postId, parentCommentId, replyWithParent);
      } catch (e) {
        // Revert on error
        await fetchComments(postId); // Refresh from server
        emit(CommentError(errMessage: e.toString(), postId: postId));
      }
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    final currentState = state;
    if (currentState is CommentLoaded) {
      final currentComments = Map<String, List<Comment>>.from(
        currentState.commentsByPost,
      );
      final postComments = List<Comment>.from(currentComments[postId] ?? []);

      // Store original state for rollback
      final originalComments = List<Comment>.from(postComments);

      // Find comment to delete and collect all its children
      final commentsToDelete = <String>{commentId};
      _collectChildComments(postComments, commentId, commentsToDelete);

      // Optimistic update - remove all comments that should be deleted
      postComments.removeWhere((c) => commentsToDelete.contains(c.id));

      // Update parent's childCommentIds if the deleted comment was a reply
      final deletedComment = originalComments.firstWhere(
        (c) => c.id == commentId,
        orElse: () => throw Exception('Comment not found'),
      );

      if (deletedComment.parentCommentId != null) {
        final parentIndex = postComments.indexWhere(
          (c) => c.id == deletedComment.parentCommentId,
        );
        if (parentIndex != -1) {
          final parentComment = postComments[parentIndex];
          final updatedChildIds = List<String>.from(
            parentComment.childCommentIds,
          )..remove(commentId);
          postComments[parentIndex] = parentComment.copyWith(
            childCommentIds: updatedChildIds,
          );
        }
      }

      final organizedComments = _organizeComments(postComments);
      currentComments[postId] = organizedComments;
      emit(CommentLoaded(commentsByPost: currentComments));

      try {
        await commentRepo.deleteComment(postId, commentId);
      } catch (e) {
        // Revert on error
        final revertedComments = _organizeComments(originalComments);
        currentComments[postId] = revertedComments;
        emit(CommentLoaded(commentsByPost: currentComments));
        emit(
          CommentError(
            errMessage: 'Error deleting comment: $e',
            postId: postId,
          ),
        );
      }
    }
  }

  Future<void> editComment(
    String postId,
    String commentId,
    String newText, {
    bool? isMarkdown,
  }) async {
    final currentState = state;
    if (currentState is CommentLoaded) {
      final currentComments = Map<String, List<Comment>>.from(
        currentState.commentsByPost,
      );
      final postComments = List<Comment>.from(currentComments[postId] ?? []);

      final commentIndex = postComments.indexWhere(
        (comment) => comment.id == commentId,
      );
      if (commentIndex == -1) return;

      final oldComment = postComments[commentIndex];
      final updatedComment = oldComment.copyWith(
        text: newText,
        timestamp: DateTime.now(),
        isMarkdown: isMarkdown ?? oldComment.isMarkdown,
      );

      // Optimistic update
      postComments[commentIndex] = updatedComment;
      final organizedComments = _organizeComments(postComments);
      currentComments[postId] = organizedComments;
      emit(CommentLoaded(commentsByPost: currentComments));

      try {
        await commentRepo.editComment(
          postId,
          commentId,
          newText,
          isMarkdown: isMarkdown,
        );
      } catch (e) {
        // Revert on error
        postComments[commentIndex] = oldComment;
        final revertedComments = _organizeComments(postComments);
        currentComments[postId] = revertedComments;
        emit(CommentLoaded(commentsByPost: currentComments));
        emit(CommentError(errMessage: e.toString(), postId: postId));
      }
    }
  }

  // Helper method to organize comments in a tree structure
  List<Comment> _organizeComments(List<Comment> flatComments) {
    final organized = <Comment>[];
    final commentMap = <String, Comment>{};

    // Create a map for quick lookup
    for (final comment in flatComments) {
      commentMap[comment.id] = comment;
    }

    // Add root comments first
    for (final comment in flatComments) {
      if (comment.isRootComment) {
        organized.add(comment);
        // Add its children recursively
        _addChildComments(comment, commentMap, organized);
      }
    }

    return organized;
  }

  // Helper method to add child comments in order
  void _addChildComments(
    Comment parent,
    Map<String, Comment> commentMap,
    List<Comment> organized,
  ) {
    for (final childId in parent.childCommentIds) {
      final child = commentMap[childId];
      if (child != null) {
        organized.add(child);
        // Recursively add children of this child
        _addChildComments(child, commentMap, organized);
      }
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

  // Helper method to get comments for a specific post
  List<Comment> getCommentsForPost(String postId) {
    final currentState = state;
    if (currentState is CommentLoaded) {
      return currentState.getCommentsForPost(postId);
    }
    return [];
  }

  // Method to refresh comments for a specific post
  Future<void> refreshComments(String postId) async {
    final currentState = state;
    Map<String, List<Comment>> currentComments = {};

    if (currentState is CommentLoaded) {
      currentComments = Map.from(currentState.commentsByPost);
    }

    emit(CommentLoading(postId: postId));

    try {
      final comments = await commentRepo.fetchCommentsByPostId(postId);
      final organizedComments = _organizeComments(comments);
      currentComments[postId] = organizedComments;
      emit(CommentLoaded(commentsByPost: currentComments));
    } catch (e) {
      emit(
        CommentError(
          errMessage: "Failed to refresh comments: $e",
          postId: postId,
        ),
      );
    }
  }

  // Method to clear comments for a specific post (useful for memory management)
  void clearCommentsForPost(String postId) {
    final currentState = state;
    if (currentState is CommentLoaded) {
      final currentComments = Map<String, List<Comment>>.from(
        currentState.commentsByPost,
      );
      currentComments.remove(postId);
      emit(CommentLoaded(commentsByPost: currentComments));
    }
  }
}
