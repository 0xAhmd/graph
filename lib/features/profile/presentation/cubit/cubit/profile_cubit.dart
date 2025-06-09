import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:ig_mate/features/profile/data/repo/profile_user_repo.dart';
import 'package:ig_mate/features/profile/domain/entities/profile_user.dart';
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
}
