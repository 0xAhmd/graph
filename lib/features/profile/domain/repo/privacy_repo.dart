// lib/features/profile/domain/repo/privacy_repo.dart

import 'package:ig_mate/features/private/domain/entities/privacy_settings.dart';

abstract class PrivacyRepoContract {
  // Update user's privacy settings
  Future<void> updatePrivacySettings({
    required String userId,
    required bool isPrivate,
  });

  // Get user's privacy settings
  Future<PrivacySettingsEntity?> getPrivacySettings(String userId);

  // Check if a user's profile is private
  Future<bool> isUserPrivate(String userId);

  // Stream privacy settings for real-time updates
  Stream<PrivacySettingsEntity?> streamPrivacySettings(String userId);
}
