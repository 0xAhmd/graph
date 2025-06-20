import 'package:json_annotation/json_annotation.dart';
part 'post_entity.g.dart';

@JsonSerializable()
class Post {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final String imageUrl;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime timeStamp;
  @JsonKey(defaultValue: <String>[])
  final List<String> likes;
  @JsonKey(defaultValue: 0)
  final int commentCount; // Track number of comments

  Post({
    required this.id,
    required this.likes,
    required this.userId,
    required this.userName,
    required this.text,
    required this.imageUrl,
    required this.timeStamp,
    this.commentCount = 0,
  });

  Post copyWith({
    String? imageUrl,
    List<String>? likes,
    String? id,
    String? userId,
    String? userName,
    String? text,
    DateTime? timeStamp,
    int? commentCount,
  }) {
    return Post(
      likes: likes ?? this.likes,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      timeStamp: timeStamp ?? this.timeStamp,
      commentCount: commentCount ?? this.commentCount,
    );
  }

  static DateTime _fromJson(String date) => DateTime.parse(date);
  static String _toJson(DateTime date) => date.toIso8601String();

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);
}
