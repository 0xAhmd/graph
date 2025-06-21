// lib/features/stories/data/repositories/stories_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ig_mate/features/stories/domain/entities/story.dart';
import 'package:ig_mate/features/stories/domain/repo/story_repo_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

import '../models/story_model.dart';

class StoriesRepositoryImpl implements StoriesRepository {
  final FirebaseFirestore _firestore;
  final SupabaseClient _supabase;

  StoriesRepositoryImpl({
    required FirebaseFirestore firestore,
    required SupabaseClient supabase,
  }) : _firestore = firestore,
       _supabase = supabase;

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
      final fileName = 'story_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final _ = await _supabase.storage
          .from('story-images')
          .upload(fileName, file);

      return _supabase.storage.from('story-images').getPublicUrl(fileName);
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
}
