import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import '../../../data/repo/profile_user_repo.dart';
import '../../../domain/entities/profile_user.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileUserRepo repo;
  bool _isUploading = false;
  List<String> _blockedUserIds = [];
  ProfileCubit(this.repo) : super(ProfileInitial());
  List<String> get blockedUserIds => _blockedUserIds;

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

  // Add this method to your ProfileCubit class

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

  // FIXED: Improved toggle follow method
  Future<void> toggleFollow(String currentUid, String targetUid) async {
    try {
      // Perform the toggle operation
      await repo.toggleFollow(currentUid: currentUid, targetUid: targetUid);

      // Refresh the profile to get the updated follow status
      await fetchUserProfile(targetUid);
    } catch (e) {
      debugPrint('Error in toggleFollow cubit: $e');
      emit(
        ProfileError(
          errMessage: 'Failed to update follow status: ${e.toString()}',
        ),
      );
    }
  } // Block user methods

  Future<List<String>> loadBlockedUsers(String currentUserId) async {
    try {
      _blockedUserIds = await repo.getBlockedUsersUids(currentUserId);
      return _blockedUserIds;
    } catch (e) {
      debugPrint('Error loading blocked users: $e');
      return [];
    }
  }

  Future<void> blockUser(String currentUserId, String userId) async {
    try {
      await repo.blockUser(currentUserId, userId);
      _blockedUserIds.add(userId);
      // Emit current state to trigger UI update
      if (state is ProfileLoaded) {
        emit(
          ProfileLoaded(
            profileUserEntity: (state as ProfileLoaded).profileUserEntity,
          ),
        );
      }
    } catch (e) {
      emit(ProfileError(errMessage: 'Failed to block user: ${e.toString()}'));
    }
  }

  Future<void> unBlockUser(String currentUserId, String blockedUserId) async {
    try {
      await repo.unBlockUser(currentUserId, blockedUserId);
      _blockedUserIds.remove(blockedUserId);
      // Emit current state to trigger UI update
      if (state is ProfileLoaded) {
        emit(
          ProfileLoaded(
            profileUserEntity: (state as ProfileLoaded).profileUserEntity,
          ),
        );
      }
    } catch (e) {
      emit(ProfileError(errMessage: 'Failed to unblock user: ${e.toString()}'));
    }
  }

  bool isUserBlocked(String userId) {
    return _blockedUserIds.contains(userId);
  }

  Future<void> updatedProfile({
    required String uid,
    String? newBio,
    String? newEmail,
  }) async {
    emit(ProfileLoading());
    try {
      final currentUser = await repo.fetchUserProfile(uid);
      if (currentUser == null) {
        emit(ProfileError(errMessage: 'failed to fetch user info'));
        return;
      }

      // Create updated profile with new fields
      final updatedProfile = currentUser.copyWith(
        newBio: newBio ?? currentUser.bio,
        newEmail: newEmail ?? currentUser.email,
        newLastEmailUpdate: (newEmail != null && newEmail != currentUser.email)
            ? DateTime.now().millisecondsSinceEpoch
            : currentUser.lastEmailUpdate,
      );

      // 🔍 DEBUG: Print what we're trying to save

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
}
