import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../domain/entities/comment.dart';
import '../utils/comment_constants.dart';
import '../utils/comment_helpers.dart';


class CommentTextDisplay extends StatefulWidget {
  final Comment comment;

  const CommentTextDisplay({
    super.key,
    required this.comment,
  });

  @override
  State<CommentTextDisplay> createState() => _CommentTextDisplayState();
}

class _CommentTextDisplayState extends State<CommentTextDisplay> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final text = widget.comment.text;
    final showSeeMore = CommentHelpers.shouldShowSeeMore(text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Content
        if (widget.comment.isMarkdown)
          MarkdownBody(
            data: _getDisplayText(text, showSeeMore),
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .copyWith(
              p: TextStyle(
                color: theme.onSurface,
                fontSize: CommentConstants.contentTextSize,
              ),
              code: TextStyle(
                backgroundColor: theme.surfaceContainerHighest,
                color: theme.primary,
              ),
            ),
          )
        else
          Text(
            _getDisplayText(text, showSeeMore),
            style: TextStyle(
              color: theme.onSurface,
              fontSize: CommentConstants.contentTextSize,
            ),
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
              style: const TextStyle(fontSize: CommentConstants.actionTextSize),
            ),
          ),
      ],
    );
  }

  String _getDisplayText(String text, bool showSeeMore) {
    if (isExpanded || !showSeeMore) {
      return text;
    }

    if (text.length > CommentConstants.textTruncateLength) {
      return CommentHelpers.truncateText(text);
    }

    return text.split('\n').take(2).join('\n');
  }
}