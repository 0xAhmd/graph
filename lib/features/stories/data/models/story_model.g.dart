// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoryModel _$StoryModelFromJson(Map<String, dynamic> json) => StoryModel(
  id: json['id'] as String,
  userId: json['userId'] as String,
  username: json['username'] as String,
  userProfileImageUrl: json['userProfileImageUrl'] as String?,
  content: json['content'] as String?,
  imageUrl: json['imageUrl'] as String?,
  backgroundColor: json['backgroundColor'] as String?,
  textColor: json['textColor'] as String?,
  fontSize: (json['fontSize'] as num?)?.toDouble(),
  fontWeight: json['fontWeight'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  expiresAt: DateTime.parse(json['expiresAt'] as String),
  isActive: json['isActive'] as bool,
  viewers: (json['viewers'] as List<dynamic>).map((e) => e as String).toList(),
  viewCount: (json['viewCount'] as num).toInt(),
);

Map<String, dynamic> _$StoryModelToJson(StoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'username': instance.username,
      'userProfileImageUrl': instance.userProfileImageUrl,
      'content': instance.content,
      'imageUrl': instance.imageUrl,
      'backgroundColor': instance.backgroundColor,
      'textColor': instance.textColor,
      'fontSize': instance.fontSize,
      'fontWeight': instance.fontWeight,
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'isActive': instance.isActive,
      'viewers': instance.viewers,
      'viewCount': instance.viewCount,
    };
