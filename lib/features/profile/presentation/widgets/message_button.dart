// lib/features/profile/presentation/widgets/enhanced_message_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubit/cubit/auth_cubit.dart';
import '../../../chat/presentation/cubit/chat_cubit.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../domain/entities/profile_user.dart';

class EnhancedMessageButton extends StatefulWidget {
  final ProfileUserEntity profileUser;
  final bool isOwnProfile;
  final bool isFollowing;

  const EnhancedMessageButton({
    super.key,
    required this.profileUser,
    required this.isOwnProfile,
    required this.isFollowing,
  });

  @override
  State<EnhancedMessageButton> createState() => _EnhancedMessageButtonState();
}

class _EnhancedMessageButtonState extends State<EnhancedMessageButton> {
  bool _isLoading = false;

  // Check if message button should be visible
  bool get _shouldShowMessageButton {
    if (widget.isOwnProfile) return false;
    return !widget.profileUser.isPrivate || widget.isFollowing;
  }

  Future<void> _handleMessageTap() async {
    if (_isLoading) return;

    final currentUser = context.read<AuthCubit>().currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final chatCubit = context.read<ChatCubit>();

      // Check if conversation already exists
      final existingConversation = await chatCubit.getExistingConversation(
        currentUser.uid,
        widget.profileUser.uid,
      );

      if (existingConversation != null) {
        // Navigate to existing conversation
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ChatPage(conversation: existingConversation),
            ),
          );
        }
      } else {
        // Create new conversation
        await chatCubit.startConversation(
          currentUser.uid,
          widget.profileUser.uid,
        );

        // Listen for conversation creation
        if (mounted) {
          final state = chatCubit.state;
          if (state is ChatConversationCreated) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ChatPage(conversation: state.conversation),
              ),
            );
          } else if (state is ChatError) {
            _showErrorSnackBar(state.message);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to start conversation: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  // ...existing code...

  @override
  Widget build(BuildContext context) {
    if (!_shouldShowMessageButton) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.secondary,
      ),
      child: MaterialButton(
        onPressed: _isLoading ? null : _handleMessageTap,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.message_outlined,
                    color: colorScheme.inversePrimary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Message',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.inversePrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Helper class for message button logic
class MessageButtonLogic {
  static bool shouldShowMessageButton({
    required bool isOwnProfile,
    required bool isPrivate,
    required bool isFollowing,
  }) {
    if (isOwnProfile) return false;
    return !isPrivate || isFollowing;
  }

  static bool canSendMessage({
    required bool isOwnProfile,
    required bool isPrivate,
    required bool isFollowing,
  }) {
    return shouldShowMessageButton(
      isOwnProfile: isOwnProfile,
      isPrivate: isPrivate,
      isFollowing: isFollowing,
    );
  }
}
