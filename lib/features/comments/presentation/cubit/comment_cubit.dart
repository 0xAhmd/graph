import 'dart:math' as Math;

import 'package:bloc/bloc.dart';
import 'package:ig_mate/features/comments/domain/repo/comment_repo_interface.dart';
import 'package:meta/meta.dart';
import '../../domain/entities/comment.dart';

part 'comment_state.dart';

class CommentCubit extends Cubit<CommentState> {
  final CommentRepoContract commentRepo;

  CommentCubit({required this.commentRepo}) : super(CommentInitial());

  Future<void> fetchComments(String postId) async {
    print('🔍 Fetching comments for postId: $postId');

    emit(CommentLoading(postId: postId));
    try {
      print('📡 Calling repository to fetch comments...');
      final comments = await commentRepo.fetchCommentsByPostId(postId);
      print('📝 Received ${comments.length} comments from repository');

      for (var comment in comments) {
        print(
          '  Comment: ${comment.id} - ${comment.text.substring(0, Math.min(20, comment.text.length))}...',
        );
      }

      final organizedComments = _organizeComments(comments);
      print('🏗️ Organized ${organizedComments.length} comments');

      emit(CommentLoaded(commentsByPost: {postId: organizedComments}));
      print('✅ Comments loaded successfully for postId: $postId');
    } catch (e, stackTrace) {
      print('❌ Error fetching comments: $e');
      print('Stack trace: $stackTrace');
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
      await fetchComments(postId);
    } catch (e) {
      emit(CommentError(errMessage: e.toString(), postId: postId));
    }
  }

  Future<void> deleteCommentSafe(String postId, String commentId) async {
    print('🗑️ Attempting to delete comment: $commentId from post: $postId');
    emit(CommentLoading(postId: postId));

    try {
      print('📡 Calling repository to delete comment...');
      await commentRepo.deleteComment(postId, commentId);
      print('✅ Comment deleted successfully from server');
      await fetchComments(postId);
    } catch (e, stackTrace) {
      print('❌ Error deleting comment from server: $e');
      print('Stack trace: $stackTrace');

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
    print('🏗️ Organizing ${flatComments.length} comments...');
    final organized = <Comment>[];
    final commentMap = <String, Comment>{};

    for (final comment in flatComments) {
      commentMap[comment.id] = comment;
    }

    print('📋 Created comment map with ${commentMap.length} entries');

    final rootComments = flatComments.where((c) => c.isRootComment).toList();
    print('🌳 Found ${rootComments.length} root comments');

    for (final comment in rootComments) {
      organized.add(comment);
      _addChildComments(comment, commentMap, organized);
    }

    print('✅ Organized into ${organized.length} comments');
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
