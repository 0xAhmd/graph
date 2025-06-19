import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import '../../domain/entities/chat_convo.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_user.dart';
import '../../domain/repo/chat_repo_contract.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this.chatRepo) : super(ChatInitial());
  final ChatRepoContract chatRepo;
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;
  StreamSubscription<ChatConversation>? _conversationSubscription;
  // Load available users to chat with
  Future<void> loadAvailableUsers(String currentUserId) async {
    try {
      emit(ChatLoading());
      final users = await chatRepo.getAvailableUsers(currentUserId);
      emit(ChatUsersLoaded(users));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  // Load user conversations
  Future<void> loadConversations(String userId) async {
    try {
      emit(ChatLoading());
      final conversations = await chatRepo.getUserConversations(userId);
      emit(ChatConversationsLoaded(conversations));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  // Start a conversation
  Future<void> startConversation(String userId1, String userId2) async {
    try {
      emit(ChatLoading());
      final conversation = await chatRepo.getOrCreateConversation(
        userId1,
        userId2,
      );
      emit(ChatConversationCreated(conversation));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  // Load messages for a conversation
  void loadMessages(String chatId, String currentUserId) {
    try {
      emit(ChatLoading());

      // Cancel previous subscription
      _messagesSubscription?.cancel();

      // Listen to messages
      _messagesSubscription = chatRepo
          .getMessages(chatId)
          .listen(
            (messages) {
              emit(ChatMessagesLoaded(messages));
              // Mark messages as read
              chatRepo.markMessagesAsRead(chatId, currentUserId);
            },
            onError: (error) {
              emit(ChatError(error.toString()));
            },
          );
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  // Listen to conversation updates
  void listenToConversation(String chatId) {
    _conversationSubscription?.cancel();

    _conversationSubscription = chatRepo
        .listenToConversation(chatId)
        .listen(
          (conversation) {
            // Emit conversation update if needed
            if (state is ChatMessagesLoaded) {
              // Keep current messages state but update conversation info
            }
          },
          onError: (error) {
            emit(ChatError(error.toString()));
          },
        );
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      if (content.trim().isEmpty) return;

      await chatRepo.sendMessage(
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        content: content.trim(),
      );

      // Message will be automatically updated through the stream
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  // Edit a message
  Future<void> editMessage(String messageId, String newContent) async {
    try {
      if (newContent.trim().isEmpty) return;

      await chatRepo.editMessage(messageId, newContent.trim());
      // Message update will be reflected through the stream
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await chatRepo.deleteMessage(messageId);
      // Message deletion will be reflected through the stream
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  // Get unread message count
  Future<void> loadUnreadCount(String userId) async {
    try {
      final count = await chatRepo.getUnreadMessageCount(userId);
      emit(ChatUnreadCountLoaded(count));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  // Update user online status
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await chatRepo.updateUserOnlineStatus(userId, isOnline);
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    _conversationSubscription?.cancel();
    return super.close();
  }
}
