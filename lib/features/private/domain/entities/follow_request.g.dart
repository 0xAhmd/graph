// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FollowRequestEntity _$FollowRequestEntityFromJson(Map<String, dynamic> json) =>
    FollowRequestEntity(
      id: json['id'] as String,
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      status:
          $enumDecodeNullable(_$FollowRequestStatusEnumMap, json['status']) ??
          FollowRequestStatus.pending,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$FollowRequestEntityToJson(
  FollowRequestEntity instance,
) => <String, dynamic>{
  'id': instance.id,
  'fromUserId': instance.fromUserId,
  'toUserId': instance.toUserId,
  'status': _$FollowRequestStatusEnumMap[instance.status]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$FollowRequestStatusEnumMap = {
  FollowRequestStatus.pending: 'pending',
  FollowRequestStatus.accepted: 'accepted',
  FollowRequestStatus.declined: 'declined',
};
