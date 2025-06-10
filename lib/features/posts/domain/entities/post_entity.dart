import 'package:ig_mate/features/posts/domain/entities/comment.dart';
import 'package:json_annotation/json_annotation.dart';
part 'post_entity.g.dart';

@JsonSerializable()
class Post {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final String imageUrl;
  @JsonKey(defaultValue: <Comment>[])
  final List<Comment> comments;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime timeStamp;
  @JsonKey(defaultValue: <String>[])
  final List<String> likes;
  
  Post({
    required this.comments,
    required this.id,
    required this.likes,
    required this.userId,
    required this.userName,
    required this.text,
    required this.imageUrl,
    required this.timeStamp,
  });

  // Updated copyWith method to handle all fields including comments
  Post copyWith({
    String? imageUrl,
    List<Comment>? comments,
    List<String>? likes,
    String? id,
    String? userId,
    String? userName,
    String? text,
    DateTime? timeStamp,
  }) {
    return Post(
      comments: comments ?? this.comments,
      likes: likes ?? this.likes,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      timeStamp: timeStamp ?? this.timeStamp,
    );
  }

  static DateTime _fromJson(String date) => DateTime.parse(date);
  static String _toJson(DateTime date) => date.toIso8601String();
  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  Map<String, dynamic> toJson() => _$PostToJson(this);
}