// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileUserEntity _$ProfileUserEntityFromJson(Map<String, dynamic> json) =>
    ProfileUserEntity(
      lastEmailUpdate: (json['lastEmailUpdate'] as num?)?.toInt() ?? 0,
      followers:
          (json['followers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      followings:
          (json['followings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      bio: json['bio'] as String? ?? '',
      profileImgUrl: json['profileImgUrl'] as String? ?? '',
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );

Map<String, dynamic> _$ProfileUserEntityToJson(ProfileUserEntity instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'name': instance.name,
      'email': instance.email,
      'bio': instance.bio,
      'profileImgUrl': instance.profileImgUrl,
      'followers': instance.followers,
      'followings': instance.followings,
      'lastEmailUpdate': instance.lastEmailUpdate,
    };
