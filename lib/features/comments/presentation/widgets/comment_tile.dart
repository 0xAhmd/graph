// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:ig_mate/features/comments/domain/entities/comment.dart';
import 'package:ig_mate/features/comments/presentation/widgets/content/comment_content_widget.dart';
import 'package:ig_mate/features/comments/presentation/widgets/dialogs/comment_edit_dialog.dart';
import 'package:ig_mate/features/comments/presentation/widgets/dialogs/comment_options_menu.dart';
import 'package:ig_mate/features/comments/presentation/widgets/reply/comment_replies_list.dart';
import 'package:ig_mate/features/comments/presentation/widgets/reply/comment_reply_input.dart';
import 'package:ig_mate/features/comments/presentation/widgets/utils/comment_constants.dart';
import 'package:ig_mate/features/comments/presentation/widgets/utils/comment_helpers.dart';
import 'package:ig_mate/features/profile/presentation/pages/profile_page.dart';
import 'comment_avatar.dart';

class CommentTile extends StatefulWidget {
  final Comment comment;
  final String currentUserId;
  final VoidCallback onDeleteComment;
  final Function(String commentId, String newText)? onEditComment;
  final bool showReplies;
  final List<Comment>? replies;

  const CommentTile({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.onDeleteComment,
    this.onEditComment,
    this.showReplies = true,
    this.replies,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile>
    with TickerProviderStateMixin {
  bool isReplying = false;
  bool showReplies = false;
  late AnimationController _replyAnimationController;
  late Animation<double> _replyAnimation;
  late AnimationController _repliesAnimationController;
  late Animation<double> _repliesAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimationControllers();
  }

  @override
  void dispose() {
    _replyAnimationController.dispose();
    _repliesAnimationController.dispose();
    super.dispose();
  }

  void _initializeAnimationControllers() {
    _replyAnimationController = AnimationController(
      duration: CommentConstants.replyAnimationDuration,
      vsync: this,
    );
    _replyAnimation = CurvedAnimation(
      parent: _replyAnimationController,
      curve: CommentConstants.defaultAnimationCurve,
    );

    _repliesAnimationController = AnimationController(
      duration: CommentConstants.repliesAnimationDuration,
      vsync: this,
    );
    _repliesAnimation = CurvedAnimation(
      parent: _repliesAnimationController,
      curve: CommentConstants.defaultAnimationCurve,
    );
  }

  bool get isOwnComment => widget.comment.userId == widget.currentUserId;

  Color get avatarColor => CommentHelpers.getAvatarColor(widget.comment.userId);

  void _toggleReply() {
    setState(() {
      isReplying = !isReplying;
    });

    if (isReplying) {
      _replyAnimationController.forward();
    } else {
      _replyAnimationController.reverse();
    }
  }

  void _toggleReplies() {
    setState(() {
      showReplies = !showReplies;
    });

    if (showReplies) {
      _repliesAnimationController.forward();
    } else {
      _repliesAnimationController.reverse();
    }
  }

  void _showEditCommentDialog() {
    CommentEditDialog.show(context: context, comment: widget.comment);
  }

  void _showOptionsMenu() {
    CommentOptionsMenu.show(
      context: context,
      comment: widget.comment,
      isOwnComment: isOwnComment,
      onEdit: _showEditCommentDialog,
      onDelete: widget.onDeleteComment,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(
        left: widget.comment.depth * CommentConstants.commentDepthIndent,
        top: 4,
        bottom: 4,
      ),
      child: Column(
        children: [
          Padding(
            padding: CommentConstants.commentPadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommentAvatar(
                  userName: widget.comment.userName,
                  userId: widget.comment.userId,
                  profileImageUrl: widget
                      .comment
                      .userProfileImageUrl, // Add this field to your Comment entity
                  color: avatarColor,
                  onTap: _navigateToProfile,
                ),
                const SizedBox(width: CommentConstants.avatarSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommentContentWidget(
                        comment: widget.comment,
                        replies: widget.replies,
                        isReplying: isReplying,
                        showReplies: showReplies,
                        onOptionsPressed: _showOptionsMenu,
                        onReplyPressed: _toggleReply,
                        onRepliesPressed: _toggleReplies,
                      ),
                      if (isReplying)
                        CommentReplyInput(
                          parentComment: widget.comment,
                          animation: _replyAnimation,
                          onCancel: _toggleReply,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Replies list
          if (showReplies)
            CommentRepliesList(
              replies: widget.replies,
              animation: _repliesAnimation,
              currentUserId: widget.currentUserId,
              onDeleteComment: widget.onDeleteComment,
              onEditComment: widget.onEditComment,
            ),

          // Separator line for nested comments
          if (widget.comment.depth > 0)
            Container(
              margin: const EdgeInsets.only(left: 40),
              height: 1,
              color: theme.outline.withOpacity(0.1),
            ),
        ],
      ),
    );
  }

  void _navigateToProfile() {
    // Navigate to user profile page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(uid: widget.currentUserId),
      ),
    );
  }
}
