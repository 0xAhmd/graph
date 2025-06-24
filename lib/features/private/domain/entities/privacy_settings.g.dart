// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrivacySettingsEntity _$PrivacySettingsEntityFromJson(
  Map<String, dynamic> json,
) => PrivacySettingsEntity(
  userId: json['userId'] as String,
  isPrivate: json['isPrivate'] as bool? ?? false,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$PrivacySettingsEntityToJson(
  PrivacySettingsEntity instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'isPrivate': instance.isPrivate,
  'updatedAt': instance.updatedAt.toIso8601String(),
};
