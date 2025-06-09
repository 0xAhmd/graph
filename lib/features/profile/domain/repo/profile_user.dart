import 'package:ig_mate/features/profile/domain/entities/profile_user.dart';

abstract class ProfileUserRepoDomain {
  Future<ProfileUserEntity?> fetchUserProfile(String uid);
  Future<void> updateUserProfile(ProfileUserEntity profileUser);
}
