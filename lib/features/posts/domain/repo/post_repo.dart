import 'package:ig_mate/features/posts/domain/entities/post_entity.dart';

abstract class PostRepoContract {
  Future<List<Post>> fetchAllPosts();
  Future<void> createPost(Post post);
  Future<void> deletePost(String postId);
  Future<List<Post>> fetchPostsByUserId(String userId);
}
