import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ig_mate/features/profile/domain/entities/profile_user.dart';
import 'package:ig_mate/features/profile/domain/repo/profile_user.dart';
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
          final followers = List<String>.from(userData['followings'] ?? []);
          final followings = List<String>.from(userData['followers'] ?? []);
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
      debugPrint(e.toString());
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
        'profileImgUrl': publicUrl, // ← consistent with fetchUserProfile
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
      final targetUserDoc = await firestore
          .collection('users')
          .doc(targetUid)
          .get();

      final currentUserDoc = await firestore
          .collection('users')
          .doc(currentUid)
          .get();

      if (currentUserDoc.exists && targetUserDoc.exists) {
        final currentUserData = currentUserDoc.data();
        final targetUserData = targetUserDoc.data();

        if (currentUserData != null && targetUserData != null) {
          final List<String> currentFollowing = List<String>.from(
            currentUserData['following'] ?? [],
          );

          if (currentFollowing.contains(targetUid)) {
            await firestore.collection('users').doc(currentUid).update({
              'following': FieldValue.arrayRemove([targetUid]),
            });
            await firestore.collection('users').doc(targetUid).update({
              'followers': FieldValue.arrayRemove([currentUid]),
            });
          } else {
            await firestore.collection('users').doc(currentUid).update({
              'following': FieldValue.arrayUnion([targetUid]),
            });
            await firestore.collection('users').doc(targetUid).update({
              'followers': FieldValue.arrayUnion([currentUid]),
            });
          }
        }
      }
    } catch (e) {}
  }
}
