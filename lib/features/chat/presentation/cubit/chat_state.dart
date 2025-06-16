part of 'chat_cubit.dart';

@immutable
sealed class ChatState {}

final class ChatInitial extends ChatState {}

final class ChatLoading extends ChatState {}

final class ChatUsersLoaded extends ChatState {
  final List<ChatUser> users;
  ChatUsersLoaded(this.users);
}

final class ChatConversationsLoaded extends ChatState {
  final List<ChatConversation> conversations;
  ChatConversationsLoaded(this.conversations);
}

final class ChatConversationCreated extends ChatState {
  final ChatConversation conversation;
  ChatConversationCreated(this.conversation);
}

final class ChatMessagesLoaded extends ChatState {
  final List<ChatMessage> messages;
  ChatMessagesLoaded(this.messages);
}

final class ChatUnreadCountLoaded extends ChatState {
  final int count;
  ChatUnreadCountLoaded(this.count);
}

final class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}
