// lib/features/follow_requests/domain/entities/follow_request.dart

import 'package:json_annotation/json_annotation.dart';

part 'follow_request.g.dart';

enum FollowRequestStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('accepted')
  accepted,
  @JsonValue('declined')
  declined,
}

@JsonSerializable()
class FollowRequestEntity {
  final String id;
  final String fromUserId;
  final String toUserId;
  @JsonKey(defaultValue: FollowRequestStatus.pending)
  final FollowRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FollowRequestEntity({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  FollowRequestEntity copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    FollowRequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FollowRequestEntity(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => _$FollowRequestEntityToJson(this);

  factory FollowRequestEntity.fromJson(Map<String, dynamic> json) =>
      _$FollowRequestEntityFromJson(json);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FollowRequestEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FollowRequestEntity(id: $id, fromUserId: $fromUserId, toUserId: $toUserId, status: $status)';
  }
}
