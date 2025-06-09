import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ig_mate/features/profile/domain/entities/profile_user.dart';
import 'package:ig_mate/features/profile/domain/repo/profile_user.dart';

class ProfileUserRepo implements ProfileUserRepoDomain {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  @override
  Future<ProfileUserEntity?> fetchUserProfile(String uid) async {
    try {
      final userDoc = await firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data();

        if (userData != null) {
          return ProfileUserEntity(
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
}
