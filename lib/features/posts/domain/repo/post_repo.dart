import 'dart:io';

import '../entities/comment.dart';
import '../entities/post_entity.dart';

abstract class PostRepoContract {
  Future<List<Post>> fetchAllPosts();
  Future<void> createPost(Post post);
  Future<void> deletePost(String postId, {String? imageExt});
  Future<List<Post>> fetchPostsByUserId(String userId);
  Future<String?> uploadPostImage(File file, String postId);
  Future<void> toggleLikes(String postId, String userId);
  Future<void> addComments(String postId, Comment comment);
  Future<void> deleteComment(String postId, String commentId);
  Future<void> editComment(String postId , String commentId , String newText);
}
