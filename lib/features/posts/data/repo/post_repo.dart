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
  final CollectionReference userCollection = FirebaseFirestore.instance
      .collection('users');

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

  /// Fetches posts for "For You" feed with privacy filtering
  /// Shows public posts + private posts from accounts the current user follows
  @override
  Future<List<Post>> fetchForYouPosts(String currentUserId) async {
    try {
      // First, get the current user's following list
      final currentUserDoc = await userCollection.doc(currentUserId).get();
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>?;
      final followingList = List<String>.from(
        currentUserData?['following'] ?? [],
      );

      // Fetch all posts
      final postsSnapshot = await postCollection
          .orderBy('timeStamp', descending: true)
          .get();

      // Get all unique user IDs from posts to batch fetch user privacy settings
      final userIds = postsSnapshot.docs
          .map(
            (doc) => (doc.data() as Map<String, dynamic>)['userId'] as String,
          )
          .toSet()
          .toList();

      // Batch fetch user privacy settings
      final userPrivacyMap = await _fetchUserPrivacySettings(userIds);

      // Filter posts based on privacy rules
      final filteredPosts = <Post>[];

      for (final doc in postsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final postUserId = data['userId'] as String;
        final isPrivate = userPrivacyMap[postUserId] ?? false;

        // Include post if:
        // 1. Account is public, OR
        // 2. Account is private AND current user follows them, OR
        // 3. Current user is the post owner
        if (!isPrivate ||
            followingList.contains(postUserId) ||
            postUserId == currentUserId) {
          // Calculate comment count
          final comments = data['comments'] as List<dynamic>? ?? [];
          data['commentCount'] = comments.length;
          data.remove('comments');

          filteredPosts.add(Post.fromJson(data));
        }
      }

      return filteredPosts;
    } catch (e) {
      throw Exception("Error fetching For You posts: $e");
    }
  }

  /// Fetches posts for "Following" feed
  /// Shows all posts from accounts the current user follows (including private accounts)
  @override
  Future<List<Post>> fetchFollowingPosts(String currentUserId) async {
    try {
      // Get the current user's following list
      final currentUserDoc = await userCollection.doc(currentUserId).get();
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>?;
      final followingList = List<String>.from(
        currentUserData?['following'] ?? [],
      );

      if (followingList.isEmpty) {
        return []; // Return empty list if not following anyone
      }

      // Fetch posts only from followed users
      final postsSnapshot = await postCollection
          .where('userId', whereIn: followingList)
          .orderBy('timeStamp', descending: true)
          .get();

      return postsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Calculate comment count
        final comments = data['comments'] as List<dynamic>? ?? [];
        data['commentCount'] = comments.length;
        data.remove('comments');

        return Post.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception("Error fetching Following posts: $e");
    }
  }

  /// Helper method to batch fetch user privacy settings
  Future<Map<String, bool>> _fetchUserPrivacySettings(
    List<String> userIds,
  ) async {
    try {
      final userPrivacyMap = <String, bool>{};

      // Firestore 'whereIn' has a limit of 10 items, so we need to batch the requests
      const batchSize = 10;

      for (int i = 0; i < userIds.length; i += batchSize) {
        final batch = userIds.skip(i).take(batchSize).toList();

        final usersSnapshot = await userCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in usersSnapshot.docs) {
          final userData = doc.data() as Map<String, dynamic>?;
          userPrivacyMap[doc.id] = userData?['isPrivate'] ?? false;
        }
      }

      return userPrivacyMap;
    } catch (e) {

      // Return empty map on error - this will treat all accounts as public (safer fallback)
      return {};
    }
  }

  /// Checks if a specific user account is private
  @override
  Future<bool> isUserAccountPrivate(String userId) async {
    try {
      final userDoc = await userCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      return userData?['isPrivate'] ?? false;
    } catch (e) {

      return false; // Default to public on error
    }
  }

  /// Checks if current user is following a specific user
  @override
  Future<bool> isFollowingUser(
    String currentUserId,
    String targetUserId,
  ) async {
    try {
      final currentUserDoc = await userCollection.doc(currentUserId).get();
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>?;
      final followingList = List<String>.from(
        currentUserData?['following'] ?? [],
      );
      return followingList.contains(targetUserId);
    } catch (e) {

      return false;
    }
  }

  /// Fetches posts with privacy check for profile viewing
  /// This is useful when viewing someone else's profile
  @override
  Future<List<Post>> fetchUserPostsWithPrivacyCheck(
    String targetUserId,
    String currentUserId,
  ) async {
    try {
      // Check if target user account is private
      final isPrivate = await isUserAccountPrivate(targetUserId);

      // If account is private and current user is not following (and not viewing own profile)
      if (isPrivate &&
          targetUserId != currentUserId &&
          !(await isFollowingUser(currentUserId, targetUserId))) {
        return []; // Return empty list - cannot view private posts
      }

      // Otherwise, fetch posts normally
      return await fetchPostsByUserId(targetUserId);
    } catch (e) {
      throw Exception("Error fetching user posts with privacy check: $e");
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
