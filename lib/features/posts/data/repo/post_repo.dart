import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ig_mate/features/posts/domain/entities/post_entity.dart';
import 'package:ig_mate/features/posts/domain/repo/post_repo.dart';

class PostRepo implements PostRepoContract {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final CollectionReference collectionReference = FirebaseFirestore.instance
      .collection('posts');
  @override
  Future<void> createPost(Post post) async {
    try {
      await collectionReference.doc(post.id).set(post.toJson());
    } catch (e) {
      throw Exception("Error creating post $e");
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      await collectionReference.doc(postId).delete();
    } on Exception catch (e) {
      throw Exception("Error deleting post: $e");
    }
  }

  @override
  Future<List<Post>> fetchAllPosts() async {
    try {
      final postsSnapshot = await collectionReference
          .orderBy('timestamp', descending: true)
          .get();

      final List<Post> allPosts = postsSnapshot.docs
          .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      return allPosts;
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  @override
  Future<List<Post>> fetchPostsByUserId(String userId) async {
    try {
      final postSnapShot = await collectionReference
          .where('userId', isEqualTo: userId)
          .get();

      final userPost = postSnapShot.docs
          .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      return userPost;
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}
