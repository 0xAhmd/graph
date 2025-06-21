import 'package:flutter/material.dart';

class CommentConstants {
  // Animation durations
  static const Duration inputAnimationDuration = Duration(milliseconds: 200);
  static const Duration switcherAnimationDuration = Duration(milliseconds: 200);

  // Dimensions
  static const double inputBorderRadius = 24.0;
  static const double postButtonSize = 18.0;
  static const double postButtonPadding = 12.0;
  static const double statsIconSize = 16.0;
  static const double sortIconSize = 20.0;
  static const double emptyStateIconSize = 80.0;
  static const double errorStateIconSize = 64.0;

  // Spacing
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );
  static const EdgeInsets statsPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  );

  // Text styles
  static const double statsTextSize = 14.0;
  static const double helperTextSize = 11.0;
  static const double characterCountSize = 12.0;
  static const double emptyStateTitleSize = 20.0;
  static const double emptyStateSubtitleSize = 14.0;
  static const double errorStateTitleSize = 18.0;
  static const double errorStateSubtitleSize = 14.0;

  // Opacity values
  static const double disabledOpacity = 0.3;
  static const double secondaryOpacity = 0.6;
  static const double subtleOpacity = 0.3;
  static const double borderOpacity = 0.2;
  static const double shadowOpacity = 0.1;

  // Sort options
  static const String sortNewest = 'newest';
  static const String sortOldest = 'oldest';
  static const String sortMostReplies = 'most_replies';

  static const Map<String, String> sortLabels = {
    sortNewest: 'Newest First',
    sortOldest: 'Oldest First',
    sortMostReplies: 'Most Replies',
  };

  static const Map<String, IconData> sortIcons = {
    sortNewest: Icons.access_time,
    sortOldest: Icons.history,
    sortMostReplies: Icons.forum,
  };

  // Markdown helper text
  static const String markdownHelperText =
      'Markdown: **bold**, *italic*, `code`, [link](url)';

  // Toast messages
  static const String commentPostedSuccess = "Comment posted successfully";
  static const String commentPostFailed = "Failed to post comment";
  static const String commentEmpty = "Comment cannot be empty";
  static const String commentInappropriate =
      "Comment contains inappropriate content";

  // Loading and empty state messages
  static const String loadingComments = 'Loading comments...';
  static const String noCommentsTitle = 'No comments yet';
  static const String noCommentsSubtitle =
      'Be the first to share your thoughts!';
  static const String errorLoadingTitle = 'Error loading comments';
  static const String retryButtonLabel = 'Retry';
  static const String refreshTooltip = 'Refresh comments';

  // Input placeholders
  static const String commentPlaceholder = 'Add a comment...';
  static const String markdownCommentPlaceholder =
      'Add a comment... (Markdown supported)';
}
