import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/core/utils/comment_organizer.dart';
import 'package:ig_mate/features/comments/presentation/cubit/comment_cubit.dart';
import 'package:ig_mate/features/comments/presentation/widgets/comment_tile.dart';

import '../../domain/entities/comment.dart';
import '../../../auth/domain/entities/app_user.dart';
import 'comment_stats_header.dart';
import 'comment_empty_state.dart';
import 'comment_error_state.dart';

class CommentListView extends StatelessWidget {
  final String postId;
  final AppUser currentUser;
  final String sortBy;
  final ValueChanged<String> onSortChanged;
  final Function(String) onDeleteComment;
  final Function(String, String) onEditComment;

  const CommentListView({
    super.key,
    required this.postId,
    required this.currentUser,
    required this.sortBy,
    required this.onSortChanged,
    required this.onDeleteComment,
    required this.onEditComment,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CommentCubit, CommentState>(
      listener: (context, state) {
        if (state is CommentError && state.postId == postId) {
          // Error handling is done in the error state widget
        }
      },
      builder: (context, state) {
        if (_shouldShowLoading(state)) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoActivityIndicator(),
                SizedBox(height: 16),
                Text('Loading comments...'),
              ],
            ),
          );
        }

        if (_hasErrorForCurrentPost(state)) {
          return CommentErrorState(
            errorState: state as CommentError,
            onRetry: () => context.read<CommentCubit>().fetchComments(postId),
          );
        }

        final comments = _getCommentsForCurrentPost(state);

        if (comments.isEmpty) {
          return const CommentEmptyState();
        }

        return Column(
          children: [
            CommentStatsHeader(
              comments: comments,
              sortBy: sortBy,
              onSortChanged: onSortChanged,
            ),
            Expanded(
              child: _buildCommentsList(comments),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommentsList(List<Comment> comments) {
    final parentComments = getParentComments(comments);
    final repliesMap = organizeComments(comments);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: parentComments.length,
      itemBuilder: (context, index) {
        final comment = parentComments[index];
        final replies = repliesMap[comment.id] ?? [];

        return CommentTile(
          comment: comment,
          currentUserId: currentUser.uid,
          onDeleteComment: () => onDeleteComment(comment.id),
          onEditComment: onEditComment,
          replies: replies,
          showReplies: true,
        );
      },
    );
  }

  bool _shouldShowLoading(CommentState state) {
    if (state is CommentLoading && state.postId == postId) {
      return true;
    }
    if (state is CommentInitial) {
      return true;
    }
    if (state is CommentLoaded && !state.commentsByPost.containsKey(postId)) {
      return true;
    }
    return false;
  }

  List<Comment> _getCommentsForCurrentPost(CommentState state) {
    if (state is CommentLoaded) {
      return state.getCommentsForPost(postId);
    }
    return [];
  }

  bool _hasErrorForCurrentPost(CommentState state) {
    return state is CommentError && state.postId == postId;
  }
}