import '../../../../core/utils/text_bomb_detector.dart';

class CommentValidators {
  static const int maxCommentLength = 700;
  static const int warningThreshold = 600;

  static String? validateComment(String text) {
    final trimmedText = text.trim();
    
    if (trimmedText.isEmpty) {
      return "Comment cannot be empty";
    }
    
    if (trimmedText.length > maxCommentLength) {
      return "Comment is too long (max $maxCommentLength characters)";
    }
    
    if (isTextBomb(trimmedText)) {
      return "Comment contains inappropriate content";
    }
    
    return null;
  }

  static bool isNearLimit(String text) {
    return text.length > warningThreshold;
  }

  static bool isOverLimit(String text) {
    return text.length > maxCommentLength;
  }

  static String getCharacterCountText(String text) {
    return '${text.length}/$maxCommentLength';
  }
}