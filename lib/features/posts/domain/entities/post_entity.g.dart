// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post _$PostFromJson(Map<String, dynamic> json) => Post(
  id: json['id'] as String,
  likes:
      (json['likes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  userId: json['userId'] as String,
  userName: json['userName'] as String,
  text: json['text'] as String,
  imageUrl: json['imageUrl'] as String,
  timeStamp: Post._fromJson(json['timeStamp'] as String),
);

Map<String, dynamic> _$PostToJson(Post instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'userName': instance.userName,
  'text': instance.text,
  'imageUrl': instance.imageUrl,
  'timeStamp': Post._toJson(instance.timeStamp),
  'likes': instance.likes,
};
