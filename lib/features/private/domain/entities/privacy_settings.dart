// lib/features/profile/domain/entities/privacy_settings.dart

import 'package:json_annotation/json_annotation.dart';

part 'privacy_settings.g.dart';

@JsonSerializable()
class PrivacySettingsEntity {
  final String userId;
  @JsonKey(defaultValue: false)
  final bool isPrivate;
  final DateTime updatedAt;

  const PrivacySettingsEntity({
    required this.userId,
    required this.isPrivate,
    required this.updatedAt,
  });

  PrivacySettingsEntity copyWith({
    String? userId,
    bool? isPrivate,
    DateTime? updatedAt,
  }) {
    return PrivacySettingsEntity(
      userId: userId ?? this.userId,
      isPrivate: isPrivate ?? this.isPrivate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => _$PrivacySettingsEntityToJson(this);

  factory PrivacySettingsEntity.fromJson(Map<String, dynamic> json) =>
      _$PrivacySettingsEntityFromJson(json);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrivacySettingsEntity && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'PrivacySettingsEntity(userId: $userId, isPrivate: $isPrivate)';
  }
}