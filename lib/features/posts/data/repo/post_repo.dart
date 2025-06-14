import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repo/post_repo.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/post_entity.dart';

class PostRepo implements PostRepoContract {
  final _bucket = Supabase.instance.client.storage.from('images');
  // ignore: unused_field
  final _firestore = FirebaseFirestore.instance;
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
      final postSnapShot = await postCollection
          .where('userId', isEqualTo: userId)
          .get();
      return postSnapShot.docs
          .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  // Add CORS headers when uploading
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
        fileOptions: FileOptions(
          contentType: mimeType,
          // Add cache control for web compatibility
          cacheControl: '3600',
        ),
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
        final post = Post.fromJson(postDoc.data() as Map<String, dynamic>);
        final hasLiked = post.likes.contains(userId);

        if (hasLiked) {
          post.likes.remove(userId);
        } else {
          post.likes.add(userId);
        }
        await postCollection.doc(postId).update({'likes': post.likes});
      } else {
        throw Exception("Post not found");
      }
    } catch (e) {
      throw Exception("error $e");
    }
  }

  @override
  Future<void> addComments(String postId, Comment comment) async {
    try {
      final postDoc = await postCollection.doc(postId).get();
      if (postDoc.exists) {
        final post = Post.fromJson(postDoc.data() as Map<String, dynamic>);
        post.comments.add(comment);
        await postCollection.doc(postId).update({
          'comments': post.comments.map((c) => c.toJson()).toList(),
        });
      } else {
        throw Exception('Post not found');
      }
    } catch (e) {
      throw Exception("error adding comment: $e");
    }
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      final postDoc = await postCollection.doc(postId).get();
      if (postDoc.exists) {
        final post = Post.fromJson(postDoc.data() as Map<String, dynamic>);
        post.comments.removeWhere((comment) => comment.id == commentId);
        await postCollection.doc(postId).update({
          'comments': post.comments.map((c) => c.toJson()).toList(),
        });
      } else {
        throw Exception('Post not found');
      }
    } catch (e) {
      throw Exception("error deleting comment: $e");
    }
  }

  @override
  Future<void> editComment(
    String postId,
    String commentId,
    String newText,
  ) async {
    try {
      final postDoc = await postCollection.doc(postId).get();
      if (postDoc.exists) {
        final post = Post.fromJson(postDoc.data() as Map<String, dynamic>);
        final commentIndex = post.comments.indexWhere((c) => c.id == commentId);
        if (commentIndex != -1) {
          final oldComment = post.comments[commentIndex];
          // Create a new Comment with updated text
          final updatedComment = Comment(
            postId: postId,
            id: oldComment.id,
            userId: oldComment.userId,
            userName: oldComment.userName,
            text: newText,
            timestamp: DateTime.now(),
          );
          post.comments[commentIndex] = updatedComment;
          await postCollection.doc(postId).update({
            'comments': post.comments.map((c) => c.toJson()).toList(),
          });
        } else {
          throw Exception('Comment not found');
        }
      } else {
        throw Exception('Post not found');
      }
    } catch (e) {
      throw Exception("error editing comment: $e");
    }
  }
}
