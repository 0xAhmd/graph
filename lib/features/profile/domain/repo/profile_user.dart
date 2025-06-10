import 'dart:io';

import '../entities/profile_user.dart';

abstract class ProfileUserRepoContract {
  Future<ProfileUserEntity?> fetchUserProfile(String uid);
  Future<void> updateUserProfile(ProfileUserEntity profileUser);
  Future<String?> uploadUserProfileImage({
    required File image,
    required String uid,
  });

  Future<void> toggleFollow({
    required String currentUid,
    required String targetUid,
  });
}
