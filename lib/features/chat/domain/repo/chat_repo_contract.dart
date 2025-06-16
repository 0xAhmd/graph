// lib/features/chat/domain/repo/chat_repo.dart
import 'package:ig_mate/features/chat/domain/entities/chat_convo.dart';

import '../entities/chat_message.dart';
import '../entities/chat_user.dart';

abstract class ChatRepoContract {
  // Get available users to chat with (excluding blocked and non-followed users)
  Future<List<ChatUser>> getAvailableUsers(String currentUserId);

  // Get all conversations for a user
  Future<List<ChatConversation>> getUserConversations(String userId);

  // Get or create a conversation between two users
  Future<ChatConversation> getOrCreateConversation(
    String userId1,
    String userId2,
  );

  // Send a message
  Future<ChatMessage> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String content,
  });

  // Get messages for a conversation
  Stream<List<ChatMessage>> getMessages(String chatId);

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId);

  // Edit a message
  Future<void> editMessage(String messageId, String newContent);

  // Delete a message
  Future<void> deleteMessage(String messageId);

  // Get unread message count
  Future<int> getUnreadMessageCount(String userId);

  // Update user online status
  Future<void> updateUserOnlineStatus(String userId, bool isOnline);

  // Listen to conversation updates
  Stream<ChatConversation> listenToConversation(String chatId);
}
