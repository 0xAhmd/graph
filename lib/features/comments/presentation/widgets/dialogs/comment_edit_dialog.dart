import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/features/comments/domain/entities/comment.dart';
import 'package:ig_mate/features/comments/presentation/cubit/comment_cubit.dart';
import 'package:ig_mate/features/comments/presentation/widgets/utils/comment_constants.dart';
import 'package:ig_mate/features/comments/presentation/widgets/utils/comment_helpers.dart';



class CommentEditDialog {
  static void show({
    required BuildContext context,
    required Comment comment,
  }) {
    final TextEditingController controller = TextEditingController(
      text: comment.text,
    );
    bool editMarkdownMode = comment.isMarkdown;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _EditCommentContent(
            controller: controller,
            editMarkdownMode: editMarkdownMode,
            comment: comment,
            onMarkdownToggle: (value) {
              setModalState(() {
                editMarkdownMode = value;
              });
            },
            onSave: (text, isMarkdown) => _handleEditComment(
              context,
              comment,
              text,
              isMarkdown,
            ),
          ),
        ),
      ),
    );
  }

  static void _handleEditComment(
    BuildContext context,
    Comment comment,
    String newText,
    bool isMarkdown,
  ) {
    if (!CommentHelpers.validateCommentText(newText)) {
      return;
    }

    if (newText == comment.text && isMarkdown == comment.isMarkdown) {
      Navigator.pop(context);
      return;
    }

    Navigator.pop(context);

    context.read<CommentCubit>().editComment(
      comment.postId,
      comment.id,
      newText,
      isMarkdown: isMarkdown,
    );

    CommentHelpers.showToast(
      CommentConstants.commentUpdatedMessage,
      isSuccess: true,
    );
  }
}

class _EditCommentContent extends StatelessWidget {
  final TextEditingController controller;
  final bool editMarkdownMode;
  final Comment comment;
  final ValueChanged<bool> onMarkdownToggle;
  final Function(String, bool) onSave;

  const _EditCommentContent({
    required this.controller,
    required this.editMarkdownMode,
    required this.comment,
    required this.onMarkdownToggle,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: CommentConstants.modalBorderRadiusGeometry,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHandleBar(theme),
          const SizedBox(height: 16),
          _buildHeader(theme),
          const SizedBox(height: 16),
          _buildTextField(theme),
          if (editMarkdownMode) _buildMarkdownHelp(theme),
          const SizedBox(height: 16),
          _buildActionButtons(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHandleBar(ThemeData theme) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurfaceVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Edit Comment',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        _buildMarkdownToggle(theme),
      ],
    );
  }

  Widget _buildMarkdownToggle(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.text_format,
          size: 16,
          color: editMarkdownMode
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 4),
        Switch(
          value: editMarkdownMode,
          onChanged: onMarkdownToggle,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  Widget _buildTextField(ThemeData theme) {
    return TextField(
      style: TextStyle(
        color: theme.colorScheme.onSurface,
      ),
      controller: controller,
      maxLines: null,
      minLines: 2,
      maxLength: CommentConstants.maxCommentLength,
      decoration: InputDecoration(
        hintText: editMarkdownMode
            ? 'Edit your comment... (Markdown supported)'
            : 'Edit your comment...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      autofocus: true,
    );
  }

  Widget _buildMarkdownHelp(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          CommentConstants.markdownHelpText,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => onSave(controller.text.trim(), editMarkdownMode),
          child: const Text('Save'),
        ),
      ],
    );
  }
}