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

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.imageUrl,
    required this.timeStamp,
  });

  Post copyWith({String? imageUrl}) {
    return Post(
      id: id,
      userId: userId,
      userName: userName,
      text: text,
      imageUrl: imageUrl ?? this.imageUrl,
      timeStamp: timeStamp,
    );
  }

  static DateTime _fromJson(String date) => DateTime.parse(date);
  static String _toJson(DateTime date) => date.toIso8601String();
  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  Map<String, dynamic> toJson() => _$PostToJson(this);
  // from and to json methods via json serializable
}
