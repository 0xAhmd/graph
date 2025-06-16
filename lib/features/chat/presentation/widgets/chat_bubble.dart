// lib/features/chat/presentation/widgets/chat_message_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import '../../domain/entities/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Swap the alignment: user messages (isMe) go left, received messages go right
    final alignment = isMe ? Alignment.centerLeft : Alignment.centerRight;
    final bubbleType = isMe ? BubbleType.sendBubble : BubbleType.receiverBubble;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Align(
        alignment: alignment,
        child: GestureDetector(
          onLongPress: (onEdit != null || onDelete != null)
              ? () => _showMessageOptions(context)
              : null,
          child: ChatBubble(
            clipper: ChatBubbleClipper1(type: bubbleType),
            alignment: alignment,
            margin: const EdgeInsets.only(top: 8),
            backGroundColor: _getBubbleColor(isDark, colorScheme),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: _getTextColor(isDark, colorScheme),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.isEdited) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getSecondaryColor(
                              isDark,
                              colorScheme,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'edited',
                            style: TextStyle(
                              color: _getSecondaryColor(isDark, colorScheme),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: _getSecondaryColor(isDark, colorScheme),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 8),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 16,
                          color: message.isRead
                              ? (isDark ? Colors.lightBlue : Colors.blue)
                              : _getSecondaryColor(isDark, colorScheme),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBubbleColor(bool isDark, ColorScheme colorScheme) {
    if (isMe) {
      // User messages (left side) - Blue gradient like in the image
      return isDark
          ? const Color(0xFF2196F3) // Blue for dark mode
          : const Color(0xFF2196F3); // Blue for light mode
    } else {
      // Received messages (right side) - Gray like in the image
      return isDark
          ? const Color(0xFF424242) // Dark gray for dark mode
          : const Color(0xFFE0E0E0); // Light gray for light mode
    }
  }

  Color _getTextColor(bool isDark, ColorScheme colorScheme) {
    if (isMe) {
      // User messages - white text on blue background
      return Colors.white;
    } else {
      // Received messages - dark text on gray background
      return isDark ? Colors.white : Colors.black87;
    }
  }

  Color _getSecondaryColor(bool isDark, ColorScheme colorScheme) {
    if (isMe) {
      // User messages - light white/gray for timestamps
      return Colors.white.withOpacity(0.8);
    } else {
      // Received messages - muted text color
      return isDark ? Colors.white.withOpacity(0.7) : Colors.black54;
    }
  }

  void _showMessageOptions(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (onEdit != null)
              _buildOptionTile(
                context,
                icon: Icons.edit_rounded,
                title: 'Edit Message',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  onEdit!();
                },
              ),
            if (onDelete != null)
              _buildOptionTile(
                context,
                icon: Icons.delete_rounded,
                title: 'Delete Message',
                isDark: isDark,
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 10),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Colors.red
        : (isDark ? Colors.white : Colors.black87);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800]?.withOpacity(0.5) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
