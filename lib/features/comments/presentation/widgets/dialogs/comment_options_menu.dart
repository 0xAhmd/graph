import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/features/comments/domain/entities/comment.dart';
import 'package:ig_mate/features/comments/presentation/cubit/comment_cubit.dart';
import 'package:ig_mate/features/comments/presentation/widgets/dialogs/comment_delete_dialog.dart';
import 'package:ig_mate/features/comments/presentation/widgets/utils/comment_constants.dart';
import 'package:ig_mate/features/comments/presentation/widgets/utils/comment_helpers.dart';


class CommentOptionsMenu {
  static void show({
    required BuildContext context,
    required Comment comment,
    required bool isOwnComment,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwnComment) ...[
              _buildEditOption(context, onEdit),
              _buildDeleteOption(context, comment, onDelete),
            ] else ...[
              _buildReportOption(context),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _buildEditOption(BuildContext context, VoidCallback onEdit) {
    return ListTile(
      leading: const Icon(Icons.edit),
      title: Text(
        'Edit comment',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onEdit();
      },
    );
  }

  static Widget _buildDeleteOption(
    BuildContext context,
    Comment comment,
    VoidCallback onDelete,
  ) {
    return ListTile(
      leading: const Icon(Icons.delete, color: Colors.red),
      title: const Text(
        'Delete comment',
        style: TextStyle(color: Colors.red),
      ),
      onTap: () {
        Navigator.pop(context);
        CommentDeleteDialog.show(
          context: context,
          comment: comment,
          onConfirm: () {
            context.read<CommentCubit>().deleteCommentSafe(
              comment.postId,
              comment.id,
            );
            onDelete();
            CommentHelpers.showToast(
              CommentConstants.commentDeletedMessage,
              isSuccess: true,
            );
          },
        );
      },
    );
  }

  static Widget _buildReportOption(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.report, color: Colors.orange),
      title: const Text('Report comment'),
      onTap: () async {
        Navigator.pop(context);
        await Future.delayed(const Duration(seconds: 1));
        CommentHelpers.showToast(
          CommentConstants.commentReportedMessage,
          isSuccess: true,
        );
      },
    );
  }
}