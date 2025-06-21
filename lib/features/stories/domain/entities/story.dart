import 'package:equatable/equatable.dart';

class StoryEntity extends Equatable {
  final String id;
  final String userId;
  final String username;
  final String? userProfileImageUrl;
  final String? content;
  final String? imageUrl;
  final String? backgroundColor;
  final String? textColor;
  final double? fontSize;
  final String? fontWeight;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;
  final List<String> viewers;
  final int viewCount;

  const StoryEntity({
    required this.id,
    required this.userId,
    required this.username,
    this.userProfileImageUrl,
    this.content,
    this.imageUrl,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.fontWeight,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
    required this.viewers,
    required this.viewCount,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get hasViewed => viewers.isNotEmpty;
  bool get isTextOnly => content != null && imageUrl == null;
  bool get isImageOnly => imageUrl != null && (content == null || content!.isEmpty);
  bool get isImageWithText => imageUrl != null && content != null && content!.isNotEmpty;
  
  @override
  List<Object?> get props => [
    id, userId, username, userProfileImageUrl, content, imageUrl,
    backgroundColor, textColor, fontSize, fontWeight, createdAt,
    expiresAt, isActive, viewers, viewCount
  ];
}