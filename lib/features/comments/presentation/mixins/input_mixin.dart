import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ig_mate/features/comments/presentation/utils/constants.dart'
    show CommentConstants;
import 'package:ig_mate/features/comments/presentation/utils/validator.dart'
    show CommentValidators;
import '../cubit/comment_cubit.dart';
import '../../domain/entities/comment.dart';
import '../../../auth/domain/entities/app_user.dart';

mixin CommentInputMixin<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  late final TextEditingController commentController;
  late final FocusNode commentFocusNode;
  late final AnimationController inputAnimationController;
  late final Animation<double> inputAnimation;

  late CommentCubit _commentCubit;
  late String _postId;
  late AppUser? _currentUser;

  bool isPosting = false;
  bool isMarkdownMode = false;

  void initializeInputMixin(CommentCubit cubit, String postId, AppUser? user) {
    _commentCubit = cubit;
    _postId = postId;
    _currentUser = user;

    commentController = TextEditingController();
    commentFocusNode = FocusNode();

    commentFocusNode.addListener(() {
      if (!commentFocusNode.hasFocus) {
        _commentCubit.fetchComments(_postId);
      }
    });

    inputAnimationController = AnimationController(
      duration: CommentConstants.inputAnimationDuration,
      vsync: this,
    );

    inputAnimation = CurvedAnimation(
      parent: inputAnimationController,
      curve: Curves.easeInOut,
    );

    commentController.addListener(_onTextChanged);
  }

  void disposeInputMixin() {
    commentController.dispose();
    commentFocusNode.dispose();
    inputAnimationController.dispose();
  }

  void _onTextChanged() {
    if (commentController.text.trim().isNotEmpty) {
      inputAnimationController.forward();
    } else {
      inputAnimationController.reverse();
    }

    // Trigger rebuild for validation state
    setState(() {});
  }

  void toggleMarkdownMode(bool value) {
    setState(() {
      isMarkdownMode = value;
    });
  }

  Future<void> postComment() async {
    final commentText = commentController.text.trim();
    final validationError = CommentValidators.validateComment(commentText);

    if (validationError != null) {
      showToast(validationError, Colors.red);
      return;
    }

    setState(() {
      isPosting = true;
    });

    final newComment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: _postId,
      userId: _currentUser!.uid,
      userName: _currentUser!.name,
      text: commentText,
      timestamp: DateTime.now(),
      isMarkdown: isMarkdownMode,
    );

    try {
      await _commentCubit.addComment(_postId, newComment);
      commentController.clear();
      commentFocusNode.unfocus();
      await _commentCubit.fetchComments(_postId);

      setState(() {
        isMarkdownMode = false;
      });
      showToast(CommentConstants.commentPostedSuccess, Colors.green);
    } catch (e) {
      showToast(CommentConstants.commentPostFailed, Colors.red);
    } finally {
      setState(() {
        isPosting = false;
      });
    }
  }

  void showToast(String message, Color color) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: color,
      textColor: Colors.white,
    );
  }
}
