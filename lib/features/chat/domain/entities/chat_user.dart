// lib/features/chat/domain/entities/chat_user.dart
import 'package:json_annotation/json_annotation.dart';

part 'chat_user.g.dart';

@JsonSerializable()
class ChatUser {
  final String uid;
  final String name;
  final String email;
  final String? profileImgUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  ChatUser({
    required this.uid,
    required this.name,
    required this.email,
    this.profileImgUrl,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) =>
      _$ChatUserFromJson(json);

  Map<String, dynamic> toJson() => _$ChatUserToJson(this);

  ChatUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? profileImgUrl,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return ChatUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImgUrl: profileImgUrl ?? this.profileImgUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
