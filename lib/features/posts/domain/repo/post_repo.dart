import 'dart:io';

import 'package:ig_mate/features/posts/domain/entities/post_entity.dart';

abstract class PostRepoContract {
  Future<List<Post>> fetchAllPosts();
  Future<void> createPost(Post post);
  Future<void> deletePost(String postId, {String? imageExt});
  Future<List<Post>> fetchPostsByUserId(String userId);
  Future<String?> uploadPostImage(File file, String postId);
  Future<void> toggleLikes(String postId, String userId);
  Future<void> updateCommentCount(String postId, int count);
  Future<List<Post>> fetchForYouPosts(String currentUserId);
  Future<List<Post>> fetchFollowingPosts(String currentUserId);
  Future<bool> isUserAccountPrivate(String userId);
  Future<bool> isFollowingUser(String currentUserId, String targetUserId);
  Future<List<Post>> fetchUserPostsWithPrivacyCheck(
    String targetUserId,
    String currentUserId,
  );
}
