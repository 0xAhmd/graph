import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ig_mate/features/comments/presentation/widgets/comment_tile.dart';
import '../../../../core/utils/text_bomb_detector.dart';
import '../../../../layout/constrained_scaffold.dart';

import '../../domain/entities/comment.dart';
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
    with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final CommentCubit commentCubit;
  late final AnimationController _inputAnimationController;
  late final Animation<double> _inputAnimation;

  AppUser? currentUser;
  bool _isPosting = false;
  bool _isMarkdownMode = false;
  String _sortBy = 'newest'; // 'newest', 'oldest', 'most_replies'

  @override
  void initState() {
    super.initState();
    commentCubit = context.read<CommentCubit>();
    currentUser = context.read<AuthCubit>().currentUser;

    // Initialize animation controller
    _inputAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _inputAnimation = CurvedAnimation(
      parent: _inputAnimationController,
      curve: Curves.easeInOut,
    );

    // Fetch comments when page loads
    commentCubit.fetchComments(widget.postId);

    // Listen to text changes for input animation
    _commentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    _inputAnimationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_commentController.text.trim().isNotEmpty) {
      _inputAnimationController.forward();
    } else {
      _inputAnimationController.reverse();
    }
  }

  void _postComment() async {
    final commentText = _commentController.text.trim();

    if (commentText.isEmpty) {
      _showToast("Comment cannot be empty", Colors.red);
      return;
    }

    if (isTextBomb(commentText)) {
      _showToast("Comment contains inappropriate content", Colors.red);
      return;
    }

    setState(() {
      _isPosting = true;
    });

    final newComment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: widget.postId,
      userId: currentUser!.uid,
      userName: currentUser!.name,
      text: commentText,
      timestamp: DateTime.now(),
      isMarkdown: _isMarkdownMode,
    );

    try {
      await commentCubit.addComment(widget.postId, newComment);
      _commentController.clear();
      _focusNode.unfocus();
      setState(() {
        _isMarkdownMode = false;
      });
      _showToast("Comment posted successfully", Colors.green);
    } catch (e) {
      _showToast("Failed to post comment", Colors.red);
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }

  void _showToast(String message, Color color) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: color,
      textColor: Colors.white,
    );
  }

  void _deleteComment(String commentId) {
    commentCubit.deleteCommentSafe(widget.postId, commentId);
  }

  void _editComment(String commentId, String newText) {
    commentCubit.editComment(widget.postId, commentId, newText);
  }

  bool _shouldShowLoading(CommentState state) {
    if (state is CommentLoading && state.postId == widget.postId) {
      return true;
    }
    if (state is CommentInitial) {
      return true;
    }
    if (state is CommentLoaded &&
        !state.commentsByPost.containsKey(widget.postId)) {
      return true;
    }
    return false;
  }

  List<Comment> _getCommentsForCurrentPost(CommentState state) {
    if (state is CommentLoaded) {
      final comments = state.getCommentsForPost(widget.postId);
      return _sortComments(comments);
    }
    return [];
  }

  List<Comment> _sortComments(List<Comment> comments) {
    final rootComments = comments.where((c) => c.isRootComment).toList();

    switch (_sortBy) {
      case 'oldest':
        rootComments.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case 'most_replies':
        rootComments.sort(
          (a, b) =>
              b.childCommentIds.length.compareTo(a.childCommentIds.length),
        );
        break;
      case 'newest':
      default:
        rootComments.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
    }

    // Rebuild the organized list maintaining the tree structure
    final organized = <Comment>[];
    final commentMap = <String, Comment>{};

    for (final comment in comments) {
      commentMap[comment.id] = comment;
    }

    for (final rootComment in rootComments) {
      organized.add(rootComment);
      _addChildCommentsRecursively(rootComment, commentMap, organized);
    }

    return organized;
  }

  void _addChildCommentsRecursively(
    Comment parent,
    Map<String, Comment> commentMap,
    List<Comment> organized,
  ) {
    // Sort child comments by timestamp (newest first for replies)
    final childIds = List<String>.from(parent.childCommentIds);
    childIds.sort((a, b) {
      final commentA = commentMap[a];
      final commentB = commentMap[b];
      if (commentA == null || commentB == null) return 0;
      return commentA.timestamp.compareTo(commentB.timestamp);
    });

    for (final childId in childIds) {
      final child = commentMap[childId];
      if (child != null) {
        organized.add(child);
        _addChildCommentsRecursively(child, commentMap, organized);
      }
    }
  }

  bool _hasErrorForCurrentPost(CommentState state) {
    return state is CommentError && state.postId == widget.postId;
  }

  Widget _buildSortButton() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.sort,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
      onSelected: (value) {
        setState(() {
          _sortBy = value;
        });
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'newest',
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                size: 20,
                color: _sortBy == 'newest'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 12),
              Text(
                'Newest First',
                style: TextStyle(
                  color: _sortBy == 'newest'
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'oldest',
          child: Row(
            children: [
              Icon(
                Icons.history,
                size: 20,
                color: _sortBy == 'oldest'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 12),
              Text(
                'Oldest First',
                style: TextStyle(
                  color: _sortBy == 'oldest'
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'most_replies',
          child: Row(
            children: [
              Icon(
                Icons.forum,
                size: 20,
                color: _sortBy == 'most_replies'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 12),
              Text(
                'Most Replies',
                style: TextStyle(
                  color: _sortBy == 'most_replies'
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentStats(List<Comment> comments) {
    final rootComments = comments.where((c) => c.isRootComment).length;
    final totalComments = comments.length;
    final repliesCount = totalComments - rootComments;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.comment_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 8),
          Text(
            '$rootComments ${rootComments == 1 ? 'comment' : 'comments'}',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (repliesCount > 0) ...[
            const SizedBox(width: 16),
            Icon(
              Icons.reply,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            Text(
              '$repliesCount ${repliesCount == 1 ? 'reply' : 'replies'}',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const Spacer(),
          _buildSortButton(),
        ],
      ),
    );
  }

  Widget _buildEnhancedCommentInput() {
    final theme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          top: BorderSide(color: theme.outline.withOpacity(0.2), width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Markdown toggle and character count
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _commentController.text.isNotEmpty
                  ? Row(
                      children: [
                        // Markdown toggle
                        Row(
                          children: [
                            Icon(
                              Icons.text_format,
                              size: 16,
                              color: _isMarkdownMode
                                  ? theme.primary
                                  : theme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Markdown',
                              style: TextStyle(
                                fontSize: 12,
                                color: _isMarkdownMode
                                    ? theme.primary
                                    : theme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: _isMarkdownMode,
                                onChanged: (value) {
                                  setState(() {
                                    _isMarkdownMode = value;
                                  });
                                },
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Character count
                        Text(
                          '${_commentController.text.length}/700',
                          style: TextStyle(
                            fontSize: 12,
                            color: _commentController.text.length > 600
                                ? theme.error
                                : theme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            if (_commentController.text.isNotEmpty && _isMarkdownMode)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Markdown: **bold**, *italic*, `code`, [link](url)',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),

            // Input row
            Row(
              children: [
                // Text field
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    maxLines: null,
                    maxLength: 700,
                    style: TextStyle(color: theme.onSurface),
                    decoration: InputDecoration(
                      hintText: _isMarkdownMode
                          ? 'Add a comment... (Markdown supported)'
                          : 'Add a comment...',
                      hintStyle: TextStyle(
                        color: theme.onSurface.withOpacity(0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: theme.outline.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: theme.outline.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: theme.primary,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Post button with animation
                ScaleTransition(
                  scale: _inputAnimation,
                  child: GestureDetector(
                    onTap: _isPosting ? null : _postComment,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            _commentController.text.trim().isNotEmpty &&
                                !_isPosting
                            ? theme.primary
                            : theme.primary.withOpacity(0.3),
                        shape: BoxShape.circle,
                        boxShadow:
                            _commentController.text.trim().isNotEmpty &&
                                !_isPosting
                            ? [
                                BoxShadow(
                                  color: theme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: _isPosting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.onPrimary,
                                ),
                              ),
                            )
                          : Icon(Icons.send, size: 18, color: theme.onPrimary),
                    ),
                  ),
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
          // Comments list
          Expanded(
            child: BlocConsumer<CommentCubit, CommentState>(
              listener: (context, state) {
                if (_hasErrorForCurrentPost(state)) {
                  final errorState = state as CommentError;
                  _showToast(errorState.errMessage, Colors.red);
                }
              },
              builder: (context, state) {
                // Show loading indicator
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

                // Show error state
                if (_hasErrorForCurrentPost(state)) {
                  final errorState = state as CommentError;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading comments',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            errorState.errMessage,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () =>
                              commentCubit.fetchComments(widget.postId),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Get comments for current post
                final comments = _getCommentsForCurrentPost(state);

                // Show empty state
                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No comments yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to share your thoughts!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Show comments list with stats
                return Column(
                  children: [
                    _buildCommentStats(comments),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return CommentTile(
                            comment: comment,
                            currentUserId: currentUser!.uid,
                            onDeleteComment: () => _deleteComment(comment.id),
                            onEditComment: _editComment,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Enhanced comment input section
          _buildEnhancedCommentInput(),
        ],
      ),
    );
  }
}
