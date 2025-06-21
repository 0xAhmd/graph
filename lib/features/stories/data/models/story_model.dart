// lib/features/stories/data/models/story_model.dart
import 'package:ig_mate/features/stories/domain/entities/story.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'story_model.g.dart';

@JsonSerializable()
class StoryModel extends StoryEntity {
  const StoryModel({
    required super.id,
    required super.userId,
    required super.username,
    super.userProfileImageUrl,
    super.content,
    super.imageUrl,
    super.backgroundColor,
    super.textColor,
    super.fontSize,
    super.fontWeight,
    required super.createdAt,
    required super.expiresAt,
    required super.isActive,
    required super.viewers,
    required super.viewCount,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) =>
      _$StoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$StoryModelToJson(this);

  factory StoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      userProfileImageUrl: data['userProfileImageUrl'],
      content: data['content'],
      imageUrl: data['imageUrl'],
      backgroundColor: data['backgroundColor'],
      textColor: data['textColor'],
      fontSize: data['fontSize']?.toDouble(),
      fontWeight: data['fontWeight'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      viewers: List<String>.from(data['viewers'] ?? []),
      viewCount: data['viewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'userProfileImageUrl': userProfileImageUrl,
      'content': content,
      'imageUrl': imageUrl,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'fontSize': fontSize,
      'fontWeight': fontWeight,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isActive': isActive,
      'viewers': viewers,
      'viewCount': viewCount,
    };
  }
}