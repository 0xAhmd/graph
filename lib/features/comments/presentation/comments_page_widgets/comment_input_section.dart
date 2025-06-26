import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/validator.dart';

class CommentInputSection extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isPosting;
  final bool isMarkdownMode;
  final Animation<double> inputAnimation;
  final VoidCallback onPost;
  final ValueChanged<bool> onMarkdownToggle;

  const CommentInputSection({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isPosting,
    required this.isMarkdownMode,
    required this.inputAnimation,
    required this.onPost,
    required this.onMarkdownToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: CommentConstants.inputAnimationDuration,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          top: BorderSide(
            color: theme.outline.withOpacity(CommentConstants.borderOpacity),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadow.withOpacity(CommentConstants.shadowOpacity),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInputControls(context, theme),
            if (controller.text.isNotEmpty && isMarkdownMode)
              _buildMarkdownHelper(theme),
            _buildInputRow(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInputControls(BuildContext context, ColorScheme theme) {
    return AnimatedSwitcher(
      duration: CommentConstants.switcherAnimationDuration,
      child: controller.text.isNotEmpty
          ? Row(
              children: [
                _buildMarkdownToggle(theme),
                const Spacer(),
                _buildCharacterCount(theme),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildMarkdownToggle(ColorScheme theme) {
    return Row(
      children: [
        Icon(
          Icons.text_format,
          size: 16,
          color: isMarkdownMode
              ? theme.primary
              : theme.onSurface.withOpacity(CommentConstants.secondaryOpacity),
        ),
        const SizedBox(width: 4),
        Text(
          'Markdown',
          style: TextStyle(
            fontSize: CommentConstants.characterCountSize,
            color: isMarkdownMode
                ? theme.primary
                : theme.onSurface.withOpacity(
                    CommentConstants.secondaryOpacity,
                  ),
          ),
        ),
        const SizedBox(width: 4),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: isMarkdownMode,
            onChanged: onMarkdownToggle,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterCount(ColorScheme theme) {
    return Text(
      CommentValidators.getCharacterCountText(controller.text),
      style: TextStyle(
        fontSize: CommentConstants.characterCountSize,
        color: CommentValidators.isNearLimit(controller.text)
            ? theme.error
            : theme.onSurface.withOpacity(CommentConstants.secondaryOpacity),
      ),
    );
  }

  Widget _buildMarkdownHelper(ColorScheme theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        CommentConstants.markdownHelperText,
        style: TextStyle(
          fontSize: CommentConstants.helperTextSize,
          color: theme.onSurface.withOpacity(CommentConstants.secondaryOpacity),
        ),
      ),
    );
  }

  Widget _buildInputRow(BuildContext context, ColorScheme theme) {
    final hasError = CommentValidators.validateComment(controller.text) != null;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: null,
            maxLength: CommentValidators.maxCommentLength,
            style: TextStyle(color: theme.onSurface),
            decoration: InputDecoration(
              hintText: isMarkdownMode
                  ? CommentConstants.markdownCommentPlaceholder
                  : CommentConstants.commentPlaceholder,
              hintStyle: TextStyle(
                color: theme.onSurface.withOpacity(
                  CommentConstants.secondaryOpacity,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  CommentConstants.inputBorderRadius,
                ),
                borderSide: BorderSide(
                  color: theme.outline.withOpacity(
                    CommentConstants.subtleOpacity,
                  ),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  CommentConstants.inputBorderRadius,
                ),
                borderSide: BorderSide(
                  color: hasError
                      ? theme.primary.withOpacity(0.5)
                      : theme.outline.withOpacity(
                          CommentConstants.subtleOpacity,
                        ),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  CommentConstants.inputBorderRadius,
                ),
                borderSide: BorderSide(
                  color: hasError ? theme.primary : theme.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: CommentConstants.inputPadding,
              counterText: '',
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildPostButton(theme),
      ],
    );
  }

  Widget _buildPostButton(ColorScheme theme) {
    final canPost =
        controller.text.trim().isNotEmpty &&
        !isPosting &&
        CommentValidators.validateComment(controller.text) == null;

    return ScaleTransition(
      scale: inputAnimation,
      child: GestureDetector(
        onTap: canPost ? onPost : null,
        child: AnimatedContainer(
          duration: CommentConstants.inputAnimationDuration,
          padding: const EdgeInsets.all(CommentConstants.postButtonPadding),
          decoration: BoxDecoration(
            color: canPost
                ? theme.primary
                : theme.primary.withOpacity(CommentConstants.disabledOpacity),
            shape: BoxShape.circle,
            boxShadow: canPost
                ? [
                    BoxShadow(
                      color: theme.primary.withOpacity(
                        CommentConstants.subtleOpacity,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: isPosting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.onPrimary),
                  ),
                )
              : Icon(
                  Icons.send,
                  size: CommentConstants.postButtonSize,
                  color: theme.inversePrimary,
                ),
        ),
      ),
    );
  }
}
