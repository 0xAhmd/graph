import 'package:bloc/bloc.dart';
import 'package:ig_mate/features/comments/domain/repo/comment_repo_interface.dart';
import 'package:meta/meta.dart';
import '../../domain/entities/comment.dart';

part 'comment_state.dart';

class CommentCubit extends Cubit<CommentState> {
  final CommentRepoContract commentRepo;

  CommentCubit({required this.commentRepo}) : super(CommentInitial());

  Future<void> fetchComments(String postId) async {
    emit(CommentLoading());
    try {
      final comments = await commentRepo.fetchCommentsByPostId(postId);
      emit(CommentLoaded(comments: comments));
    } catch (e) {
      emit(CommentError(errMessage: "Failed to load comments: $e"));
    }
  }

  Future<void> addComment(String postId, Comment comment) async {
    final currentState = state;
    if (currentState is CommentLoaded) {
      // Optimistic update
      final updatedComments = [...currentState.comments, comment];
      emit(CommentLoaded(comments: updatedComments));

      try {
        await commentRepo.addComment(postId, comment);
      } catch (e) {
        // Revert on error
        emit(CommentLoaded(comments: currentState.comments));
        emit(CommentError(errMessage: e.toString()));
      }
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    final currentState = state;
    if (currentState is CommentLoaded) {
      final deletedComment = currentState.comments.firstWhere(
        (comment) => comment.id == commentId,
        orElse: () => throw Exception('Comment not found'),
      );

      // Optimistic update
      final updatedComments = currentState.comments
          .where((comment) => comment.id != commentId)
          .toList();
      emit(CommentLoaded(comments: updatedComments));

      try {
        await commentRepo.deleteComment(postId, commentId);
      } catch (e) {
        // Revert on error
        final revertedComments = [...updatedComments, deletedComment];
        emit(CommentLoaded(comments: revertedComments));
        emit(CommentError(errMessage: 'Error deleting comment: $e'));
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
      final commentIndex = currentState.comments.indexWhere(
        (comment) => comment.id == commentId,
      );

      if (commentIndex != -1) {
        final oldComment = currentState.comments[commentIndex];
        final updatedComment = oldComment.copyWith(
          text: newText,
          timestamp: DateTime.now(),
        );

        // Optimistic update
        final updatedComments = List<Comment>.from(currentState.comments);
        updatedComments[commentIndex] = updatedComment;
        emit(CommentLoaded(comments: updatedComments));

        try {
          await commentRepo.editComment(postId, commentId, newText);
        } catch (e) {
          // Revert on error
          final revertedComments = List<Comment>.from(updatedComments);
          revertedComments[commentIndex] = oldComment;
          emit(CommentLoaded(comments: revertedComments));
          emit(CommentError(errMessage: e.toString()));
        }
      }
    }
  }
}
