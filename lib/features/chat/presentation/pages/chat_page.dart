// lib/features/chat/presentation/pages/chat_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:ig_mate/features/chat/presentation/widgets/chat_input_field.dart';
import 'package:ig_mate/features/posts/presentation/widgets/custom_bottom_sheet.dart';
import '../../../../layout/constrained_scaffold.dart';
import '../../../auth/presentation/cubit/cubit/auth_cubit.dart';
import '../../domain/entities/chat_convo.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_user.dart';
import '../cubit/chat_cubit.dart';

class ChatPage extends StatefulWidget {
  final ChatConversation conversation;

  const ChatPage({super.key, required this.conversation});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatUser? _otherUser;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = context.read<AuthCubit>().currentUser?.uid;
    if (_currentUserId != null) {
      _loadMessages();
      _loadOtherUserInfo();
    }
  }

  void _loadMessages() {
    context.read<ChatCubit>().loadMessages(
      widget.conversation.id,
      _currentUserId!,
    );
  }

  void _loadOtherUserInfo() async {
    // Get the other user's ID from conversation participants
    final otherUserId = widget.conversation.participants.firstWhere(
      (id) => id != _currentUserId,
    );

    // Load available users to get user info
    final users = await context.read<ChatCubit>().chatRepo.getAvailableUsers(
      _currentUserId!,
    );
    final otherUser = users.firstWhere(
      (user) => user.uid == otherUserId,
      orElse: () => ChatUser(uid: otherUserId, name: 'Unknown User', email: ''),
    );

    setState(() {
      _otherUser = otherUser;
    });
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty && _currentUserId != null) {
      final otherUserId = widget.conversation.participants.firstWhere(
        (id) => id != _currentUserId,
      );

      context.read<ChatCubit>().sendMessage(
        chatId: widget.conversation.id,
        senderId: _currentUserId!,
        receiverId: otherUserId,
        content: content,
      );

      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _editMessage(ChatMessage message) {
    final controller = TextEditingController(text: message.content);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,

      builder: (context) => CustomBottomSheet(
        controller: controller,
        title: 'Edit Message',
        hintText: 'Enter your message...',
        buttonLabel: 'Save',
        onPost: (newContent) {
          if (newContent.isNotEmpty && newContent != message.content) {
            context.read<ChatCubit>().editMessage(message.id, newContent);
          }
        },
      ),
    );
  }

  void _deleteMessage(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatCubit>().deleteMessage(message.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedScaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: _otherUser != null
            ? Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: _otherUser!.profileImgUrl != null
                            ? NetworkImage(_otherUser!.profileImgUrl!)
                            : null,
                        child: _otherUser!.profileImgUrl == null
                            ? Text(
                                _otherUser!.name.isNotEmpty
                                    ? _otherUser!.name[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(fontSize: 14),
                              )
                            : null,
                      ),
                      if (_otherUser!.isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _otherUser!.name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_otherUser!.isOnline)
                          const Text(
                            'Online',
                            style: TextStyle(color: Colors.green, fontSize: 12),
                          )
                        else if (_otherUser!.lastSeen != null)
                          Text(
                            _formatLastSeen(_otherUser!.lastSeen!),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              )
            : const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatCubit, ChatState>(
              listener: (context, state) {
                if (state is ChatError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        state.message,
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ChatMessagesLoaded) {
                  if (state.messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a conversation!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      final isMe = message.senderId == _currentUserId;
                      final showDate =
                          index == state.messages.length - 1 ||
                          !_isSameDay(
                            message.timestamp,
                            state.messages[index + 1].timestamp,
                          );

                      return Column(
                        children: [
                          if (showDate) _buildDateSeparator(message.timestamp),
                          ChatMessageBubble(
                            message: message,
                            isMe: isMe,
                            onEdit: isMe ? () => _editMessage(message) : null,
                            onDelete: isMe
                                ? () => _deleteMessage(message)
                                : null,
                          ),
                        ],
                      );
                    },
                  );
                }

                if (state is ChatError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 80,
                            color: Colors.red.withOpacity(0.7),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load messages',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadMessages,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          ChatInputField(controller: _messageController, onSend: _sendMessage),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatDate(date),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (_isSameDay(date, now)) {
      return 'Today';
    } else if (_isSameDay(date, yesterday)) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Last seen just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return 'Last seen ${difference.inDays}d ago';
    } else {
      return 'Last seen ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _EditMessageDialog extends StatefulWidget {
  final ChatMessage message;
  final Function(String) onEdit;

  const _EditMessageDialog({required this.message, required this.onEdit});

  @override
  State<_EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<_EditMessageDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.message.content);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Edit Message',
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
      content: TextField(
        style: TextStyle(color: Theme.of(context).colorScheme.primary),

        controller: _controller,
        maxLines: 3,
        decoration: InputDecoration(
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
          hintText: 'Enter your message...',
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final newContent = _controller.text.trim();
            if (newContent.isNotEmpty && newContent != widget.message.content) {
              widget.onEdit(newContent);
            }
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
