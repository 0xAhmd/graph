import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ig_mate/features/posts/domain/repo/post_repo.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ig_mate/features/posts/domain/entities/post_entity.dart';

class PostRepo implements PostRepoContract {
  final _bucket = Supabase.instance.client.storage.from('images');
  // ignore: unused_field
  final _firestore = FirebaseFirestore.instance;
  final CollectionReference collectionReference = FirebaseFirestore.instance
      .collection('posts');

  @override
  Future<void> createPost(Post post) async {
    try {
      await collectionReference.doc(post.id).set(post.toJson());
    } catch (e) {
      throw Exception("Error creating post: $e");
    }
  }

  @override
  Future<void> deletePost(String postId, {String? imageExt}) async {
    try {
      await collectionReference.doc(postId).delete();

      if (imageExt != null) {
        final filePath = 'posts/$postId$imageExt';
        await _bucket.remove([filePath]);
      }
    } catch (e) {
      throw Exception("Error deleting post: $e");
    }
  }

  @override
  Future<List<Post>> fetchAllPosts() async {
    try {
      final postsSnapshot = await collectionReference
          .orderBy('timeStamp', descending: true)
          .get();
      return postsSnapshot.docs
          .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
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
      return postSnapShot.docs
          .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  @override
  Future<String?> uploadPostImage(File file, String postId) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final fileBytes = await file.readAsBytes();
      final mimeType = lookupMimeType(file.path);

      await _bucket.uploadBinary(
        fileName,
        fileBytes,
        fileOptions: FileOptions(contentType: mimeType),
      );

      return _bucket.getPublicUrl(fileName);
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }
}
