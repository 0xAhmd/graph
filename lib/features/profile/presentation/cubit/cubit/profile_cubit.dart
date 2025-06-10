import 'dart:io';

import 'package:bloc/bloc.dart';
import '../../../data/repo/profile_user_repo.dart';
import '../../../domain/entities/profile_user.dart';
import 'package:meta/meta.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileUserRepo repo;
  bool _isUploading = false;

  ProfileCubit(this.repo) : super(ProfileInitial());

  Future<void> fetchUserProfile(String uid) async {
    try {
      emit(ProfileLoading());
      final user = await repo.fetchUserProfile(uid);
      if (user != null) {
        emit(ProfileLoaded(profileUserEntity: user));
      } else {
        emit(ProfileError(errMessage: 'user not found'));
      }
    } catch (e) {
      emit(ProfileError(errMessage: e.toString()));
    }
  }

  Future<ProfileUserEntity?> getUserProfile(String uid) async {
    final user = await repo.fetchUserProfile(uid);
    return user;
  }

  Future<void> updatedProfile({required String uid, String? newBio}) async {
    emit(ProfileLoading());
    try {
      final currentUser = await repo.fetchUserProfile(uid);
      if (currentUser == null) {
        emit(ProfileError(errMessage: 'failed to fetch user info'));
        return;
      }
      final updatedProfile = currentUser.copyWith(
        newBio: newBio ?? currentUser.bio,
      );
      await repo.updateUserProfile(updatedProfile);

      final refreshedUser = await repo.fetchUserProfile(uid);
      if (refreshedUser != null) {
        emit(ProfileLoaded(profileUserEntity: refreshedUser));
      } else {
        emit(ProfileError(errMessage: 'Failed to fetch updated user info'));
      }
    } catch (e) {
      emit(ProfileError(errMessage: "Error when updating the user info: $e"));
    }
  }

  Future<void> uploadProfileImage({
    required File image,
    required String uid,
  }) async {
    if (_isUploading) return;

    _isUploading = true;
    emit(ProfileImageUploading());
    try {
      final imageUrl = await repo.uploadUserProfileImage(
        image: image,
        uid: uid,
      );
      if (imageUrl == null) {
        emit(ProfileError(errMessage: 'Failed to upload profile image'));
        return;
      }

      final updatedUser = await repo.fetchUserProfile(uid);
      if (updatedUser != null) {
        emit(ProfileLoaded(profileUserEntity: updatedUser));
      } else {
        emit(
          ProfileError(
            errMessage: 'Failed to refresh profile after image upload',
          ),
        );
      }
    } catch (e) {
      emit(ProfileError(errMessage: 'Image upload failed: $e'));
    } finally {
      _isUploading = false;
    }
  }

  // toggle follow method

  Future<void> toggleFollow(String currentUid, String targetUid) async {
    try {
      await repo.toggleFollow(currentUid: currentUid, targetUid: targetUid);
    } catch (e) {
      emit(ProfileError(errMessage: e.toString()));
    }
  }
}
