// lib/features/stories/data/repo/store_repo_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ig_mate/features/stories/domain/entities/story.dart';
import 'package:ig_mate/features/stories/domain/repo/story_repo_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../models/story_model.dart';

class StoriesRepositoryImpl implements StoriesRepository {
  final FirebaseFirestore _firestore;
  final _bucket = Supabase.instance.client.storage.from('images');
  final SupabaseClient _supabase = Supabase.instance.client; // ✅ correct

  StoriesRepositoryImpl({
    required FirebaseFirestore firestore,
    SupabaseClient?
    supabase, // Make optional since we're using Supabase.instance
  }) : _firestore = firestore;

  @override
  Future<List<StoryEntity>> getActiveStories() async {
    try {
      final querySnapshot = await _firestore
          .collection('stories')
          .where('isActive', isEqualTo: true)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => StoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch active stories: $e');
    }
  }

  @override
  Future<List<StoryEntity>> getUserStories(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => StoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user stories: $e');
    }
  }

  @override
  Future<StoryEntity> createStory(StoryEntity story) async {
    try {
      final storyModel = StoryModel(
        id: story.id,
        userId: story.userId,
        username: story.username,
        userProfileImageUrl: story.userProfileImageUrl,
        content: story.content,
        imageUrl: story.imageUrl,
        backgroundColor: story.backgroundColor,
        textColor: story.textColor,
        fontSize: story.fontSize,
        fontWeight: story.fontWeight,
        createdAt: story.createdAt,
        expiresAt: story.expiresAt,
        isActive: story.isActive,
        viewers: story.viewers,
        viewCount: story.viewCount,
      );

      await _firestore
          .collection('stories')
          .doc(story.id)
          .set(storyModel.toFirestore());

      return storyModel;
    } catch (e) {
      throw Exception('Failed to create story: $e');
    }
  }

  @override
  Future<void> deleteStory(String storyId) async {
    try {
      await _firestore.collection('stories').doc(storyId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Failed to delete story: $e');
    }
  }

  @override
  Future<void> markStoryAsViewed(String storyId, String viewerId) async {
    try {
      final storyRef = _firestore.collection('stories').doc(storyId);

      await _firestore.runTransaction((transaction) async {
        final storyDoc = await transaction.get(storyRef);
        if (!storyDoc.exists) return;

        final viewers = List<String>.from(storyDoc['viewers'] ?? []);
        if (!viewers.contains(viewerId)) {
          viewers.add(viewerId);
          transaction.update(storyRef, {
            'viewers': viewers,
            'viewCount': viewers.length,
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to mark story as viewed: $e');
    }
  }

  @override
  Future<List<String>> getStoryViewers(String storyId) async {
    try {
      final doc = await _firestore.collection('stories').doc(storyId).get();
      if (!doc.exists) return [];

      return List<String>.from(doc['viewers'] ?? []);
    } catch (e) {
      throw Exception('Failed to get story viewers: $e');
    }
  }

  @override
  Future<String> uploadStoryImage(String imagePath) async {
    try {
      final file = File(imagePath);

      // Check if file exists
      if (!await file.exists()) {
        throw Exception('File does not exist at path: $imagePath');
      }

      // Use the exact same pattern as ProfileUserRepo
      final fileName = 'story_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileBytes = await file.readAsBytes();
      final mimeType = 'image/jpeg'; // Since we're saving as .jpg

      await _bucket.uploadBinary(
        fileName,
        fileBytes,
        fileOptions: FileOptions(contentType: mimeType),
      );

      final publicUrl = _bucket.getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload story image: $e');
    }
  }

  @override
  Stream<List<StoryEntity>> getStoriesStream() {
    return _firestore
        .collection('stories')
        .where('isActive', isEqualTo: true)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StoryModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Helper method to upload image from XFile (for better compatibility)
  Future<String> uploadStoryImageFromXFile(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileName = 'story_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final mimeType = 'image/jpeg';

      await _bucket.uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(contentType: mimeType),
      );

      final publicUrl = _bucket.getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload story image from XFile: $e');
    }
  }

  // Helper method to verify image URL accessibility
  Future<void> verifyImageUrl(String url) async {
    try {
      // Simple check to see if we can list the file
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 3) {
        final fileName = pathSegments.last; // Get just the filename
        final files = await _supabase.storage
            .from('images')
            .list(); // List root of images bucket

        final fileExists = files.any((file) => file.name == fileName);
        if (!fileExists) {
        } else {}
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // Alternative upload method using bytes (like your working feature might)
  Future<String> uploadStoryImageAsBytes(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'story_$timestamp.jpg';

      final _ = await _supabase.storage
          .from('images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final publicUrl = _supabase.storage.from('images').getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed alternative upload: $e');
    }
  }
}
