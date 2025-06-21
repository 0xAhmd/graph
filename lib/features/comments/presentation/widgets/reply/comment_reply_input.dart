import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/features/auth/presentation/cubit/cubit/auth_cubit.dart';
import 'package:ig_mate/features/comments/domain/entities/comment.dart';
import 'package:ig_mate/features/comments/presentation/cubit/comment_cubit.dart';
import 'package:ig_mate/features/comments/presentation/widgets/utils/comment_constants.dart';
import 'package:ig_mate/features/comments/presentation/widgets/utils/comment_helpers.dart';

class CommentReplyInput extends StatefulWidget {
  final Comment parentComment;
  final Animation<double> animation;
  final VoidCallback onCancel;

  const CommentReplyInput({
    super.key,
    required this.parentComment,
    required this.animation,
    required this.onCancel,
  });

  @override
  State<CommentReplyInput> createState() => _CommentReplyInputState();
}

class _CommentReplyInputState extends State<CommentReplyInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool isMarkdownMode = false;

  @override
  void initState() {
    super.initState();
    // Focus when animation completes
    widget.animation.addListener(() {
      if (widget.animation.isCompleted && mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _postReply() async {
    final replyText = _controller.text.trim();

    if (!CommentHelpers.validateReplyText(replyText)) {
      return;
    }

    final currentUser = context.read<AuthCubit>().currentUser;
    if (currentUser == null) return;

    final newReply = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: widget.parentComment.postId,
      userId: currentUser.uid,
      userName: currentUser.name,
      text: replyText,
      timestamp: DateTime.now(),
      parentCommentId: widget.parentComment.id,
      depth: widget.parentComment.depth + 1,
      isMarkdown: isMarkdownMode,
    );

    try {
      await context.read<CommentCubit>().addReply(
        widget.parentComment.postId,
        widget.parentComment.id,
        newReply,
      );

      _controller.clear();
      widget.onCancel();
      setState(() {
        isMarkdownMode = false;
      });

      CommentHelpers.showToast(
        CommentConstants.replyPostedMessage,
        isSuccess: true,
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return SizeTransition(
      sizeFactor: widget.animation,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: CommentConstants.commentBorderRadiusGeometry,
          border: Border.all(color: theme.outline.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with markdown toggle
            _buildHeader(theme),
            const SizedBox(height: 8),

            // Text field
            _buildTextField(theme),

            // Markdown help text
            if (isMarkdownMode) _buildMarkdownHelp(theme),

            const SizedBox(height: 12),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme theme) {
    return Row(
      children: [
        Text(
          'Reply to ${widget.parentComment.userName}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: theme.onSurface.withOpacity(0.8),
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Icon(
              Icons.text_format,
              size: 14,
              color: isMarkdownMode
                  ? theme.primary
                  : theme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Switch(
              value: isMarkdownMode,
              onChanged: (value) {
                setState(() {
                  isMarkdownMode = value;
                });
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(ColorScheme theme) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: null,
      minLines: 2,
      maxLength: CommentConstants.maxReplyLength,
      decoration: InputDecoration(
        hintText: isMarkdownMode
            ? 'Write a reply... (Markdown supported)'
            : 'Write a reply...',
        border: OutlineInputBorder(
          borderRadius: CommentConstants.inputBorderRadiusGeometry,
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: theme.surface,
        contentPadding: const EdgeInsets.all(12),
        counterText: '',
      ),
    );
  }

  Widget _buildMarkdownHelp(ColorScheme theme) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Text(
          CommentConstants.markdownHelpText,
          style: TextStyle(
            fontSize: CommentConstants.hintTextSize,
            color: theme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: _postReply, child: const Text('Reply')),
      ],
    );
  }
}
