import 'package:flutter/material.dart';
import 'package:ig_mate/features/comments/presentation/mixins/input_mixin.dart';
import 'package:ig_mate/features/comments/presentation/mixins/sorting_mixin.dart';
import '../cubit/comment_cubit.dart';
import '../../domain/entities/comment.dart';
import '../../../auth/domain/entities/app_user.dart';

mixin CommentStateMixin<T extends StatefulWidget>
    on State<T>, CommentInputMixin<T>, CommentSortingMixin<T> {
  late CommentCubit _commentCubit;
  late String _postId;

  void initializeMixins(CommentCubit cubit, String postId, AppUser? user) {
    _commentCubit = cubit;
    _postId = postId;
    initializeInputMixin(cubit, postId, user);
  }

  void disposeMixins() {
    disposeInputMixin();
  }

  bool shouldShowLoading(CommentState state) {
    if (state is CommentLoading && state.postId == _postId) {
      return true;
    }
    if (state is CommentInitial) {
      return true;
    }
    if (state is CommentLoaded && !state.commentsByPost.containsKey(_postId)) {
      return true;
    }
    return false;
  }

  List<Comment> getCommentsForCurrentPost(CommentState state) {
    if (state is CommentLoaded) {
      final comments = state.getCommentsForPost(_postId);
      return sortComments(comments);
    }
    return [];
  }

  bool hasErrorForCurrentPost(CommentState state) {
    return state is CommentError && state.postId == _postId;
  }

  void deleteComment(String commentId) {
    _commentCubit.deleteCommentSafe(_postId, commentId);
  }

  void editComment(String commentId, String newText) {
    _commentCubit.editComment(_postId, commentId, newText);
  }
}
