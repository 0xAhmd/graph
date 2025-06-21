import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ig_mate/core/utils/text_bomb_detector.dart';

class CommentHelpers {
  static String formatTimestamp(DateTime timestamp) {
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

  static Color getAvatarColor(String userId) {
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
    return colors[userId.hashCode % colors.length];
  }

  static bool validateCommentText(String text) {
    if (text.trim().isEmpty) {
      showToast("Comment cannot be empty", isError: true);
      return false;
    }

    if (isTextBomb(text)) {
      showToast("Comment contains inappropriate content", isError: true);
      return false;
    }

    return true;
  }

  static bool validateReplyText(String text) {
    if (text.trim().isEmpty) {
      showToast("Reply cannot be empty", isError: true);
      return false;
    }

    if (isTextBomb(text)) {
      showToast("Reply contains inappropriate content", isError: true);
      return false;
    }

    return true;
  }

  static void showToast(String message, {bool isError = false, bool isSuccess = false}) {
    Color backgroundColor = Colors.grey;
    if (isError) backgroundColor = Colors.red;
    if (isSuccess) backgroundColor = Colors.green;

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
    );
  }

  static bool shouldShowSeeMore(String text) {
    return text.length > 100 || text.split('\n').length > 2;
  }

  static String truncateText(String text, {int maxLength = 100}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}