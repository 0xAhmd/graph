// lib/features/chat/data/repo/firebase_chat_repo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ig_mate/features/chat/domain/entities/chat_convo.dart';
import 'package:ig_mate/features/chat/domain/entities/chat_message.dart';
import 'package:ig_mate/features/chat/domain/entities/chat_user.dart';
import 'package:ig_mate/features/chat/domain/repo/chat_repo_contract.dart';

class FirebaseChatRepo implements ChatRepoContract {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<ChatUser>> getAvailableUsers(String currentUserId) async {
    try {
      // Get current user's following list
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (!currentUserDoc.exists) return [];

      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      final following = List<String>.from(currentUserData['following'] ?? []);
      final blocked = List<String>.from(currentUserData['blocked'] ?? []);

      if (following.isEmpty) return [];

      // Get users that current user is following and not blocked
      final availableUserIds = following
          .where((uid) => !blocked.contains(uid))
          .toList();

      if (availableUserIds.isEmpty) return [];

      // Fetch user details in batches (Firestore 'in' query limit is 10)
      List<ChatUser> chatUsers = [];

      for (int i = 0; i < availableUserIds.length; i += 10) {
        final batch = availableUserIds.skip(i).take(10).toList();
        final querySnapshot = await _firestore
            .collection('users')
            .where('uid', whereIn: batch)
            .get();

        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          chatUsers.add(
            ChatUser(
              uid: data['uid'],
              name: data['name'],
              email: data['email'],
              profileImgUrl: data['profileImgUrl'],
              isOnline: data['isOnline'] ?? false,
              lastSeen: _parseDateTime(data['lastSeen']),
            ),
          );
        }
      }

      return chatUsers;
    } catch (e) {

      return [];
    }
  }

  @override
  Future<List<ChatConversation>> getUserConversations(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return ChatConversation(
          id: doc.id,
          participants: List<String>.from(data['participants']),
          lastMessage: data['lastMessage'],
          lastMessageTime: _parseDateTime(data['lastMessageTime']),
          lastMessageSenderId: data['lastMessageSenderId'],
          unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
          createdAt: _parseDateTime(data['createdAt'])!,
          updatedAt: _parseDateTime(data['updatedAt'])!,
        );
      }).toList();
    } catch (e) {

      return [];
    }
  }

  @override
  Future<ChatConversation> getOrCreateConversation(
    String userId1,
    String userId2,
  ) async {
    try {
      // Check if conversation already exists
      final existingConversation = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: userId1)
          .get();

      for (var doc in existingConversation.docs) {
        final participants = List<String>.from(doc.data()['participants']);
        if (participants.contains(userId2) && participants.length == 2) {
          final data = doc.data();
          return ChatConversation(
            id: doc.id,
            participants: participants,
            lastMessage: data['lastMessage'],
            lastMessageTime: _parseDateTime(data['lastMessageTime']),
            lastMessageSenderId: data['lastMessageSenderId'],
            unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
            createdAt: _parseDateTime(data['createdAt'])!,
            updatedAt: _parseDateTime(data['updatedAt'])!,
          );
        }
      }

      // Create new conversation
      final conversationRef = _firestore.collection('conversations').doc();
      final now = DateTime.now();

      final newConversation = ChatConversation(
        id: conversationRef.id,
        participants: [userId1, userId2],
        unreadCount: {userId1: 0, userId2: 0},
        createdAt: now,
        updatedAt: now,
      );

      await conversationRef.set(newConversation.toJson());
      return newConversation;
    } catch (e) {

      rethrow;
    }
  }

  @override
  Future<ChatMessage> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      final messageRef = _firestore.collection('messages').doc();
      final now = DateTime.now();

      final message = ChatMessage(
        id: messageRef.id,
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        timestamp: now,
      );

      // Add message
      await messageRef.set(message.toJson());

      // Update conversation
      await _firestore.collection('conversations').doc(chatId).update({
        'lastMessage': content,
        'lastMessageTime': now,
        'lastMessageSenderId': senderId,
        'updatedAt': now,
        'unreadCount.$receiverId': FieldValue.increment(1),
      });

      return message;
    } catch (e) {

      rethrow;
    }
  }

  @override
  Stream<List<ChatMessage>> getMessages(String chatId) {
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return ChatMessage(
              id: doc.id,
              chatId: data['chatId'],
              senderId: data['senderId'],
              receiverId: data['receiverId'],
              content: data['content'],
              timestamp: _parseDateTime(data['timestamp'])!,
              isRead: data['isRead'] ?? false,
              isEdited: data['isEdited'] ?? false,
              editedAt: _parseDateTime(data['editedAt']),
            );
          }).toList();
        });
  }

  @override
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      // Mark messages as read
      final unreadMessages = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      // Reset unread count in conversation
      await _firestore.collection('conversations').doc(chatId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {

    }
  }

  @override
  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'content': newContent,
        'isEdited': true,
        'editedAt': DateTime.now(),
      });
    } catch (e) {

      rethrow;
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).delete();
    } catch (e) {

      rethrow;
    }
  }

  @override
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final conversations = await getUserConversations(userId);
      int totalUnread = 0;

      for (var conversation in conversations) {
        totalUnread += conversation.unreadCount[userId] ?? 0;
      }

      return totalUnread;
    } catch (e) {

      return 0;
    }
  }

  @override
  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': DateTime.now(),
      });
    } catch (e) {

    }
  }

  @override
  Stream<ChatConversation> listenToConversation(String chatId) {
    return _firestore.collection('conversations').doc(chatId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) throw Exception('Conversation not found');

      final data = doc.data()!;
      return ChatConversation(
        id: doc.id,
        participants: List<String>.from(data['participants']),
        lastMessage: data['lastMessage'],
        lastMessageTime: _parseDateTime(data['lastMessageTime']),
        lastMessageSenderId: data['lastMessageSenderId'],
        unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
        createdAt: _parseDateTime(data['createdAt'])!,
        updatedAt: _parseDateTime(data['updatedAt'])!,
      );
    });
  }

  // Helper method to parse DateTime from either Timestamp or String
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {

        return null;
      }
    } else if (value is DateTime) {
      return value;
    }

    return null;
  }
}
