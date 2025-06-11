import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/profile_user.dart';
import '../../domain/repo/profile_user.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileUserRepo implements ProfileUserRepoContract {
  final _bucket = Supabase.instance.client.storage.from('images');
  final _firestore = FirebaseFirestore.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Future<ProfileUserEntity?> fetchUserProfile(String uid) async {
    try {
      final userDoc = await firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data();

        if (userData != null) {
          // FIXED: Consistent field mapping
          final followers = List<String>.from(userData['followers'] ?? []);
          final followings = List<String>.from(
            userData['following'] ?? [],
          ); // Changed from 'followings' to 'following'

          return ProfileUserEntity(
            followers: followers,
            followings: followings,
            bio: userData['bio'] ?? '',
            profileImgUrl: userData['profileImgUrl'] ?? '',
            uid: uid,
            name: userData['name'],
            email: userData['email'],
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  @override
  Future<void> updateUserProfile(ProfileUserEntity updatedProfile) async {
    try {
      await firestore.collection('users').doc(updatedProfile.uid).update({
        'bio': (updatedProfile.bio == 'null') ? '' : updatedProfile.bio,
        'profileImgUrl': (updatedProfile.profileImgUrl == 'null')
            ? ''
            : (updatedProfile.profileImgUrl),
      });
      print(
        'Updating: bio=${updatedProfile.bio}, profileImgUrl=${updatedProfile.profileImgUrl}',
      );
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Future<String?> uploadUserProfileImage({
    required File image,
    required String uid,
  }) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
      final fileBytes = await image.readAsBytes();
      final mimeType = lookupMimeType(image.path);

      await _bucket.uploadBinary(
        fileName,
        fileBytes,
        fileOptions: FileOptions(contentType: mimeType),
      );

      final publicUrl = _bucket.getPublicUrl(fileName);

      await _firestore.collection('users').doc(uid).update({
        'profileImgUrl': publicUrl,
      });

      return publicUrl;
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }

  @override
  Future<void> toggleFollow({
    required String currentUid,
    required String targetUid,
  }) async {
    try {
      // Use a transaction to ensure consistency
      await firestore.runTransaction((transaction) async {
        final targetUserRef = firestore.collection('users').doc(targetUid);
        final currentUserRef = firestore.collection('users').doc(currentUid);

        final targetUserDoc = await transaction.get(targetUserRef);
        final currentUserDoc = await transaction.get(currentUserRef);

        if (!currentUserDoc.exists || !targetUserDoc.exists) {
          throw Exception('User not found');
        }

        final currentUserData = currentUserDoc.data()!;
        final targetUserData = targetUserDoc.data()!;

        final List<String> currentFollowing = List<String>.from(
          currentUserData['following'] ??
              [], // FIXED: Use 'following' consistently
        );
        final List<String> targetFollowers = List<String>.from(
          targetUserData['followers'] ?? [],
        );

        if (currentFollowing.contains(targetUid)) {
          // Unfollow
          currentFollowing.remove(targetUid);
          targetFollowers.remove(currentUid);
        } else {
          // Follow
          currentFollowing.add(targetUid);
          targetFollowers.add(currentUid);
        }

        // Update both documents in the transaction
        transaction.update(currentUserRef, {'following': currentFollowing});

        transaction.update(targetUserRef, {'followers': targetFollowers});
      });

      print('Follow/Unfollow operation completed successfully');
    } catch (e) {
      print('Error in toggleFollow: $e');
      throw Exception('Failed to toggle follow: $e');
    }
  }

  @override
  Future<List<String>> getBlockedUsersUids(String currentUserId) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error getting blocked users: $e');
      return [];
    }
  }

  @override
  Future<void> blockUser(String currentUserId, String userId) async {
    try {
      debugPrint('Blocking $userId for user $currentUserId');
      await firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(userId)
          .set({'blockedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Error blocking user: $e');
      throw Exception('Failed to block user');
    }
  }

  @override
  Future<void> unBlockUser(String currentUserId, String blockedUserId) async {
    try {
      await firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(blockedUserId)
          .delete();
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      throw Exception('Failed to unblock user');
    }
  }
}
