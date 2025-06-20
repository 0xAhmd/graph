import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../domain/repo/post_repo.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/post_entity.dart';

class PostRepo implements PostRepoContract {
  final _bucket = Supabase.instance.client.storage.from('images');
  final CollectionReference postCollection = FirebaseFirestore.instance
      .collection('posts');

  @override
  Future<void> createPost(Post post) async {
    try {
      await postCollection.doc(post.id).set(post.toJson());
    } catch (e) {
      throw Exception("Error creating post: $e");
    }
  }

  @override
  Future<void> deletePost(String postId, {String? imageExt}) async {
    try {
      await postCollection.doc(postId).delete();

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
      final postsSnapshot = await postCollection
          .orderBy('timeStamp', descending: true)
          .get();

      return postsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Calculate comment count from existing comments array if it exists
        final comments = data['comments'] as List<dynamic>? ?? [];
        data['commentCount'] = comments.length;

        // Remove comments from the data since we don't need them in Post entity
        data.remove('comments');

        return Post.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  @override
  Future<List<Post>> fetchPostsByUserId(String userId) async {
    try {
      final postSnapShot = await postCollection
          .where('userId', isEqualTo: userId)
          .get();

      return postSnapShot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Calculate comment count from existing comments array if it exists
        final comments = data['comments'] as List<dynamic>? ?? [];
        data['commentCount'] = comments.length;

        // Remove comments from the data since we don't need them in Post entity
        data.remove('comments');

        return Post.fromJson(data);
      }).toList();
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
        fileOptions: FileOptions(contentType: mimeType, cacheControl: '3600'),
      );

      return _bucket.getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  @override
  Future<void> toggleLikes(String postId, String userId) async {
    try {
      final postDoc = await postCollection.doc(postId).get();

      if (postDoc.exists) {
        final data = postDoc.data() as Map<String, dynamic>;
        final likes = List<String>.from(data['likes'] ?? []);
        final hasLiked = likes.contains(userId);

        if (hasLiked) {
          likes.remove(userId);
        } else {
          likes.add(userId);
        }

        await postCollection.doc(postId).update({'likes': likes});
      } else {
        throw Exception("Post not found");
      }
    } catch (e) {
      throw Exception("error $e");
    }
  }

  @override
  Future<void> updateCommentCount(String postId, int count) async {
    try {
      await postCollection.doc(postId).update({'commentCount': count});
    } catch (e) {
      throw Exception("Error updating comment count: $e");
    }
  }
}
