
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import '../../domain/repo/comment_repo_interface.dart';
import '../../domain/entities/comment.dart';

part 'comment_state.dart';

class CommentCubit extends Cubit<CommentState> {
  final CommentRepoContract commentRepo;

  CommentCubit({required this.commentRepo}) : super(CommentInitial());

  Future<void> fetchComments(String postId) async {
    // debugPrint('🔍 Fetching comments for postId: $postId');

    emit(CommentLoading(postId: postId));
    try {
      // debugPrint('📡 Calling repository to fetch comments...');
      final comments = await commentRepo.fetchCommentsByPostId(postId);
      // debugPrint('📝 Received ${comments.length} comments from repository');


      final organizedComments = _organizeComments(comments);
      // debugPrint('🏗️ Organized ${organizedComments.length} comments');

      final currentState = state;
      if (currentState is CommentLoaded) {
        final currentComments = Map<String, List<Comment>>.from(
          currentState.commentsByPost,
        );
        currentComments[postId] = organizedComments;
        emit(CommentLoaded(commentsByPost: currentComments));
      } else {
        emit(CommentLoaded(commentsByPost: {postId: organizedComments}));
      }
      // debugPrint('✅ Comments loaded successfully for postId: $postId');
    } catch (e) {
      // debugPrint('❌ Error fetching comments: $e');
      // debugPrint('Stack trace: $stackTrace');
      emit(
        CommentError(errMessage: "Failed to load comments: $e", postId: postId),
      );
    }
  }

  Future<void> addComment(String postId, Comment comment) async {
    emit(CommentLoading(postId: postId));
    try {
      await commentRepo.addComment(postId, comment);
      await fetchComments(postId);
    } catch (e) {
      emit(CommentError(errMessage: e.toString(), postId: postId));
    }
  }

  Future<void> addReply(
    String postId,
    String parentCommentId,
    Comment reply,
  ) async {
    emit(CommentLoading(postId: postId));
    try {
      await commentRepo.addReply(postId, parentCommentId, reply);
    } catch (e) {
      emit(CommentError(errMessage: e.toString(), postId: postId));
      rethrow; // <--- this is critical
    }

    try {
      await fetchComments(postId);
    } catch (e) {
      // debugPrint('⚠️ Error in fetchComments after reply: $e');
    }
  }

  Future<void> deleteCommentSafe(String postId, String commentId) async {
    // debugPrint(
    //   '🗑️ Attempting to delete comment: $commentId from post: $postId',
    // );
    emit(CommentLoading(postId: postId));

    try {
      // debugPrint('📡 Calling repository to delete comment...');
      await commentRepo.deleteComment(postId, commentId);
      // debugPrint('✅ Comment deleted successfully from server');
      await fetchComments(postId);
    } catch (e) {
      // debugPrint('❌ Error deleting comment from server: $e');
      // debugPrint('Stack trace: $stackTrace');

      emit(
        CommentError(
          errMessage: 'Failed to delete comment: $e',
          postId: postId,
        ),
      );
    }
  }

  Future<void> editComment(
    String postId,
    String commentId,
    String newText, {
    bool? isMarkdown,
  }) async {
    emit(CommentLoading(postId: postId));
    try {
      await commentRepo.editComment(
        postId,
        commentId,
        newText,
        isMarkdown: isMarkdown,
      );
      await fetchComments(postId);
    } catch (e) {
      emit(CommentError(errMessage: e.toString(), postId: postId));
    }
  }

  List<Comment> _organizeComments(List<Comment> flatComments) {
    // debugPrint('🏗️ Organizing ${flatComments.length} comments...');
    final organized = <Comment>[];
    final commentMap = <String, Comment>{};

    for (final comment in flatComments) {
      commentMap[comment.id] = comment;
    }

    // debugPrint('📋 Created comment map with ${commentMap.length} entries');

    final rootComments = flatComments.where((c) => c.isRootComment).toList();
    // debugPrint('🌳 Found ${rootComments.length} root comments');

    for (final comment in rootComments) {
      organized.add(comment);
      _addChildComments(comment, commentMap, organized);
    }

    // debugPrint('✅ Organized into ${organized.length} comments');
    return organized;
  }

  void _addChildComments(
    Comment parent,
    Map<String, Comment> commentMap,
    List<Comment> organized,
  ) {
    for (final childId in parent.childCommentIds) {
      final child = commentMap[childId];
      if (child != null) {
        organized.add(child);
        _addChildComments(child, commentMap, organized);
      }
    }
  }

  List<Comment> getCommentsForPost(String postId) {
    final currentState = state;
    if (currentState is CommentLoaded) {
      return currentState.getCommentsForPost(postId);
    }
    return [];
  }

  Future<void> refreshComments(String postId) async {
    await fetchComments(postId);
  }

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
