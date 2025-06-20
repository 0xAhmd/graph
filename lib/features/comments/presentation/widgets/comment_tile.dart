// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ig_mate/features/comments/domain/entities/comment.dart';
import 'package:ig_mate/features/comments/presentation/cubit/comment_cubit.dart';
import '../../../../core/utils/text_bomb_detector.dart';
import '../../../auth/presentation/cubit/cubit/auth_cubit.dart';

import 'comment_avatar.dart';

class CommentTile extends StatefulWidget {
  final Comment comment;
  final String currentUserId;
  final VoidCallback onDeleteComment;
  final Function(String commentId, String newText)? onEditComment;
  final bool showReplies;

  const CommentTile({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.onDeleteComment,
    this.onEditComment,
    this.showReplies = true,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile>
    with TickerProviderStateMixin {
  bool isExpanded = false;
  bool isReplying = false;
  bool isMarkdownMode = false;
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  late AnimationController _replyAnimationController;
  late Animation<double> _replyAnimation;

  @override
  void initState() {
    super.initState();
    _replyAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _replyAnimation = CurvedAnimation(
      parent: _replyAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    _replyAnimationController.dispose();
    super.dispose();
  }

  bool get isOwnComment => widget.comment.userId == widget.currentUserId;

  Color get avatarColor {
    // Generate consistent color based on user ID
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
    ];
    return colors[widget.comment.userId.hashCode % colors.length];
  }

  void _toggleReply() {
    setState(() {
      isReplying = !isReplying;
    });

    if (isReplying) {
      _replyAnimationController.forward();
      _replyFocusNode.requestFocus();
    } else {
      _replyAnimationController.reverse();
      _replyFocusNode.unfocus();
      _replyController.clear();
    }
  }

  void _postReply() async {
    final replyText = _replyController.text.trim();

    if (replyText.isEmpty) {
      Fluttertoast.showToast(
        msg: "Reply cannot be empty",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    if (isTextBomb(replyText)) {
      Fluttertoast.showToast(
        msg: "Reply contains inappropriate content",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final currentUser = context.read<AuthCubit>().currentUser;
    if (currentUser == null) return;

    final newReply = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: widget.comment.postId,
      userId: currentUser.uid,
      userName: currentUser.name,
      text: replyText,
      timestamp: DateTime.now(),
      parentCommentId: widget.comment.id,
      depth: widget.comment.depth + 1,
      isMarkdown: isMarkdownMode,
    );

    try {
      await context.read<CommentCubit>().addReply(
        widget.comment.postId,
        widget.comment.id,
        newReply,
      );

      _replyController.clear();
      _toggleReply();
      setState(() {
        isMarkdownMode = false;
      });

      Fluttertoast.showToast(
        msg: "Reply posted successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to post reply",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _showEditCommentDialog() {
    final TextEditingController controller = TextEditingController(
      text: widget.comment.text,
    );
    bool editMarkdownMode = widget.comment.isMarkdown;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title and markdown toggle
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Edit Comment',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.text_format,
                          size: 16,
                          color: editMarkdownMode
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Switch(
                          value: editMarkdownMode,
                          onChanged: (value) {
                            setModalState(() {
                              editMarkdownMode = value;
                            });
                          },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Text field
                TextField(
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  controller: controller,
                  maxLines: null,
                  minLines: 2,
                  maxLength: 700,
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
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  autofocus: true,
                ),

                if (editMarkdownMode) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Markdown: **bold**, *italic*, `code`, [link](url)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _handleEditComment(
                        controller.text.trim(),
                        editMarkdownMode,
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleEditComment(String newText, bool isMarkdown) {
    if (newText.isEmpty) {
      Fluttertoast.showToast(
        msg: "Comment cannot be empty",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    if (isTextBomb(newText)) {
      Fluttertoast.showToast(
        msg: "Comment contains inappropriate content",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    if (newText == widget.comment.text &&
        isMarkdown == widget.comment.isMarkdown) {
      Navigator.pop(context);
      return;
    }

    Navigator.pop(context);

    context.read<CommentCubit>().editComment(
      widget.comment.postId,
      widget.comment.id,
      newText,
      isMarkdown: isMarkdown,
    );

    Fluttertoast.showToast(
      msg: "Comment updated successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Comment',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          widget.comment.hasReplies
              ? 'This will delete the comment and all its replies. Are you sure?'
              : 'Are you sure you want to delete this comment?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<CommentCubit>().deleteCommentSafe(
                widget.comment.postId,
                widget.comment.id,
              );
              if (widget.onDeleteComment != null) {
                widget.onDeleteComment();
              }
              Fluttertoast.showToast(
                msg: "Comment deleted",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.green,
                textColor: Colors.white,
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwnComment) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(
                  'Edit comment',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEditCommentDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete comment',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.report, color: Colors.orange),
                title: const Text('Report comment'),
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(seconds: 1));
                  Fluttertoast.showToast(
                    msg: "Comment reported",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.orange,
                    textColor: Colors.white,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  Widget _buildCommentContent() {
    final theme = Theme.of(context).colorScheme;
    final text = widget.comment.text;
    final showSeeMore = text.length > 100 || text.split('\n').length > 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      widget.comment.userName,
                      style: TextStyle(
                        color: theme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimestamp(widget.comment.timestamp),
                      style: TextStyle(
                        color: theme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    if (widget.comment.isMarkdown) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.text_format,
                        size: 12,
                        color: theme.primary.withOpacity(0.7),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: _showOptionsMenu,
                child: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: theme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Content
          if (widget.comment.isMarkdown)
            MarkdownBody(
              data: isExpanded
                  ? text
                  : (showSeeMore && !isExpanded
                        ? (text.length > 100
                              ? '${text.substring(0, 100)}...'
                              : text)
                        : text),
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                  .copyWith(
                    p: TextStyle(color: theme.onSurface, fontSize: 15),
                    code: TextStyle(
                      backgroundColor: theme.surfaceContainerHighest,
                      color: theme.primary,
                    ),
                  ),
            )
          else
            Text(
              isExpanded
                  ? text
                  : (showSeeMore && !isExpanded
                        ? (text.length > 100
                              ? '${text.substring(0, 100)}...'
                              : text)
                        : text),
              style: TextStyle(color: theme.onSurface, fontSize: 15),
            ),

          // See more/less button
          if (showSeeMore)
            TextButton(
              onPressed: () => setState(() => isExpanded = !isExpanded),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(top: 4),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                isExpanded ? "See less" : "See more",
                style: const TextStyle(fontSize: 13),
              ),
            ),

          // Action buttons
          const SizedBox(height: 4),
          Row(
            children: [
              if (widget.comment.canHaveReplies)
                TextButton.icon(
                  onPressed: _toggleReply,
                  icon: Icon(isReplying ? Icons.close : Icons.reply, size: 16),
                  label: Text(
                    isReplying ? 'Cancel' : 'Reply',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              if (widget.comment.hasReplies)
                TextButton(
                  onPressed: () {
                    // This could toggle showing/hiding replies
                  },
                  child: Text(
                    '${widget.comment.childCommentIds.length} ${widget.comment.childCommentIds.length == 1 ? 'reply' : 'replies'}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
    final theme = Theme.of(context).colorScheme;

    return SizeTransition(
      sizeFactor: _replyAnimation,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.outline.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Markdown toggle
            Row(
              children: [
                Text(
                  'Reply to ${widget.comment.userName}',
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
            ),
            const SizedBox(height: 8),

            // Text field
            TextField(
              controller: _replyController,
              focusNode: _replyFocusNode,
              maxLines: null,
              minLines: 2,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: isMarkdownMode
                    ? 'Write a reply... (Markdown supported)'
                    : 'Write a reply...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.surface,
                contentPadding: const EdgeInsets.all(12),
                counterText: '',
              ),
            ),

            if (isMarkdownMode) ...[
              const SizedBox(height: 4),
              Text(
                'Markdown: **bold**, *italic*, `code`, [link](url)',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.onSurface.withOpacity(0.6),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _toggleReply,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _postReply,
                  child: const Text('Reply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(
        left: widget.comment.depth * 24.0,
        top: 4,
        bottom: 4,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommentAvatar(
                  userName: widget.comment.userName,
                  color: avatarColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCommentContent(),
                      if (isReplying) _buildReplyInput(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Add a subtle line for nested comments
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
}
