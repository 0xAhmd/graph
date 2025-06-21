import 'package:flutter/material.dart';

class CommentConstants {
  // Animation durations
  static const Duration replyAnimationDuration = Duration(milliseconds: 300);
  static const Duration repliesAnimationDuration = Duration(milliseconds: 400);

  // Text limits
  static const int maxCommentLength = 700;
  static const int maxReplyLength = 500;
  static const int textTruncateLength = 100;

  // Spacing
  static const double commentDepthIndent = 24.0;
  static const double avatarSpacing = 12.0;
  static const double contentPadding = 14.0;
  static const double verticalPadding = 10.0;

  // Border radius
  static const double commentBorderRadius = 12.0;
  static const double inputBorderRadius = 8.0;
  static const double modalBorderRadius = 20.0;

  // Icon sizes
  static const double actionIconSize = 16.0;
  static const double optionsIconSize = 18.0;
  static const double markdownIconSize = 12.0;

  // Font sizes
  static const double usernameTextSize = 14.0;
  static const double timestampTextSize = 12.0;
  static const double contentTextSize = 15.0;
  static const double actionTextSize = 13.0;
  static const double hintTextSize = 11.0;

  // Markdown help text
  static const String markdownHelpText =
      'Markdown: **bold**, *italic*, `code`, [link](url)';

  // Toast messages
  static const String commentPostedMessage = 'Comment posted successfully';
  static const String replyPostedMessage = 'Reply posted successfully';
  static const String commentUpdatedMessage = 'Comment updated successfully';
  static const String commentDeletedMessage = 'Comment deleted';
  static const String commentReportedMessage = 'Comment reported';

  // Animation curves
  static const Curve defaultAnimationCurve = Curves.easeInOut;

  // Common styles
  static EdgeInsets get commentMargin =>
      const EdgeInsets.only(top: 4, bottom: 4);

  static EdgeInsets get commentPadding =>
      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0);

  static EdgeInsets get contentContainerPadding => const EdgeInsets.symmetric(
    horizontal: contentPadding,
    vertical: verticalPadding,
  );

  static BorderRadius get commentBorderRadiusGeometry =>
      BorderRadius.circular(commentBorderRadius);

  static BorderRadius get inputBorderRadiusGeometry =>
      BorderRadius.circular(inputBorderRadius);

  static BorderRadius get modalBorderRadiusGeometry =>
      const BorderRadius.vertical(top: Radius.circular(modalBorderRadius));
}
