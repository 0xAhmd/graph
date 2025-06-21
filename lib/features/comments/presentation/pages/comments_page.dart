import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/features/comments/presentation/comments_page_widgets/comment_input_section.dart';
import 'package:ig_mate/features/comments/presentation/comments_page_widgets/comment_list_view.dart';
import 'package:ig_mate/features/comments/presentation/mixins/input_mixin.dart';
import 'package:ig_mate/features/comments/presentation/mixins/sorting_mixin.dart';
import 'package:ig_mate/features/comments/presentation/mixins/state_mixin.dart';
import '../../../../layout/constrained_scaffold.dart';
import '../cubit/comment_cubit.dart';
import '../../../auth/presentation/cubit/cubit/auth_cubit.dart';
import '../../../auth/domain/entities/app_user.dart';


class CommentsPage extends StatefulWidget {
  final String postId;
  final String postUserId;

  const CommentsPage({
    super.key,
    required this.postId,
    required this.postUserId,
  });

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage>
    with 
        TickerProviderStateMixin,
        CommentInputMixin,
        CommentSortingMixin,
        CommentStateMixin {
  
  late final CommentCubit commentCubit;
  AppUser? currentUser;

  @override
  void initState() {
    super.initState();
    commentCubit = context.read<CommentCubit>();
    currentUser = context.read<AuthCubit>().currentUser;
    
    initializeMixins(commentCubit, widget.postId, currentUser);
    commentCubit.fetchComments(widget.postId);
  }

  @override
  void dispose() {
    disposeMixins();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedScaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => commentCubit.refreshComments(widget.postId),
            tooltip: 'Refresh comments',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CommentListView(
              postId: widget.postId,
              currentUser: currentUser!,
              sortBy: sortBy,
              onSortChanged: (value) => updateSortBy(value),
              onDeleteComment: deleteComment,
              onEditComment: editComment,
            ),
          ),
          CommentInputSection(
            controller: commentController,
            focusNode: commentFocusNode,
            isPosting: isPosting,
            isMarkdownMode: isMarkdownMode,
            inputAnimation: inputAnimation,
            onPost: postComment,
            onMarkdownToggle: (value) => toggleMarkdownMode(value),
          ),
        ],
      ),
    );
  }
}