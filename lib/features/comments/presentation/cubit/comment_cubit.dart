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
      currentComments[postId] = comments;
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
      currentComments[postId] = postComments;
      emit(CommentLoaded(commentsByPost: currentComments));

      try {
        await commentRepo.addComment(postId, comment);
      } catch (e) {
        // Revert on error - remove the comment we just added
        postComments.removeLast();
        currentComments[postId] = postComments;
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

  Future<void> deleteComment(String postId, String commentId) async {
    final currentState = state;
    if (currentState is CommentLoaded) {
      final currentComments = Map<String, List<Comment>>.from(
        currentState.commentsByPost,
      );
      final postComments = List<Comment>.from(currentComments[postId] ?? []);

      final deletedCommentIndex = postComments.indexWhere(
        (comment) => comment.id == commentId,
      );
      if (deletedCommentIndex == -1) return;

      final deletedComment = postComments[deletedCommentIndex];

      // Optimistic update
      postComments.removeAt(deletedCommentIndex);
      currentComments[postId] = postComments;
      emit(CommentLoaded(commentsByPost: currentComments));

      try {
        await commentRepo.deleteComment(postId, commentId);
      } catch (e) {
        // Revert on error
        postComments.insert(deletedCommentIndex, deletedComment);
        currentComments[postId] = postComments;
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
    String newText,
  ) async {
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
      );

      // Optimistic update
      postComments[commentIndex] = updatedComment;
      currentComments[postId] = postComments;
      emit(CommentLoaded(commentsByPost: currentComments));

      try {
        await commentRepo.editComment(postId, commentId, newText);
      } catch (e) {
        // Revert on error
        postComments[commentIndex] = oldComment;
        currentComments[postId] = postComments;
        emit(CommentLoaded(commentsByPost: currentComments));
        emit(CommentError(errMessage: e.toString(), postId: postId));
      }
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
      currentComments[postId] = comments;
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
