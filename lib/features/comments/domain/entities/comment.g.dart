// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment _$CommentFromJson(Map<String, dynamic> json) => Comment(
  id: Comment._stringFromAny(json['id']),
  postId: json['postId'] as String,
  userId: json['userId'] as String,
  userName: json['userName'] as String,
  text: json['text'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  parentCommentId: json['parentCommentId'] as String?,
  childCommentIds:
      (json['childCommentIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  depth: (json['depth'] as num?)?.toInt() ?? 0,
  isMarkdown: json['isMarkdown'] as bool? ?? false,
);

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
  'id': instance.id,
  'postId': instance.postId,
  'userId': instance.userId,
  'userName': instance.userName,
  'text': instance.text,
  'timestamp': instance.timestamp.toIso8601String(),
  'parentCommentId': instance.parentCommentId,
  'childCommentIds': instance.childCommentIds,
  'depth': instance.depth,
  'isMarkdown': instance.isMarkdown,
};
