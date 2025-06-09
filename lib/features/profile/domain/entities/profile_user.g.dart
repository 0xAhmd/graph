// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileUserEntity _$ProfileUserEntityFromJson(Map<String, dynamic> json) =>
    ProfileUserEntity(
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
    };
