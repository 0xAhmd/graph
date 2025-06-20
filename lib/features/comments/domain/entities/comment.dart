import 'package:json_annotation/json_annotation.dart';
part 'comment.g.dart';

@JsonSerializable()
class Comment {
  @JsonKey(fromJson: _stringFromAny)
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String text;
  final DateTime timestamp;
  final String? parentCommentId; // For nested comments
  final List<String> childCommentIds; // Track child comments
  final int
  depth; // Track nesting depth (0 = root, 1 = first level reply, etc.)
  final bool isMarkdown; // Whether the text contains markdown

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.timestamp,
    this.parentCommentId,
    this.childCommentIds = const [],
    this.depth = 0,
    this.isMarkdown = false,
  });

  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userName,
    String? text,
    DateTime? timestamp,
    String? parentCommentId,
    List<String>? childCommentIds,
    int? depth,
    bool? isMarkdown,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      childCommentIds: childCommentIds ?? this.childCommentIds,
      depth: depth ?? this.depth,
      isMarkdown: isMarkdown ?? this.isMarkdown,
    );
  }

  // Helper methods
  bool get isRootComment => parentCommentId == null;
  bool get hasReplies => childCommentIds.isNotEmpty;
  bool get canHaveReplies => depth < 3; // Limit nesting to 3 levels
  static String _stringFromAny(dynamic value) => value.toString();

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);
  Map<String, dynamic> toJson() => _$CommentToJson(this);
}
