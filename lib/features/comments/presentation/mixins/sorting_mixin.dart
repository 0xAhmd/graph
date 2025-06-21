import 'package:flutter/material.dart';
import '../../domain/entities/comment.dart';

mixin CommentSortingMixin<T extends StatefulWidget> on State<T> {
  String sortBy = 'newest';

  void updateSortBy(String value) {
    setState(() {
      sortBy = value;
    });
  }

  List<Comment> sortComments(List<Comment> comments) {
    final rootComments = comments.where((c) => c.isRootComment).toList();

    switch (sortBy) {
      case 'oldest':
        rootComments.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case 'most_replies':
        rootComments.sort(
          (a, b) =>
              b.childCommentIds.length.compareTo(a.childCommentIds.length),
        );
        break;
      case 'newest':
      default:
        rootComments.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
    }

    final organized = <Comment>[];
    final commentMap = <String, Comment>{};

    for (final comment in comments) {
      commentMap[comment.id] = comment;
    }

    for (final rootComment in rootComments) {
      organized.add(rootComment);
      _addChildCommentsRecursively(rootComment, commentMap, organized);
    }

    return organized;
  }

  void _addChildCommentsRecursively(
    Comment parent,
    Map<String, Comment> commentMap,
    List<Comment> organized,
  ) {
    final childIds = List<String>.from(parent.childCommentIds);
    childIds.sort((a, b) {
      final commentA = commentMap[a];
      final commentB = commentMap[b];
      if (commentA == null || commentB == null) return 0;
      return commentA.timestamp.compareTo(commentB.timestamp);
    });

    for (final childId in childIds) {
      final child = commentMap[childId];
      if (child != null) {
        organized.add(child);
        _addChildCommentsRecursively(child, commentMap, organized);
      }
    }
  }
}
