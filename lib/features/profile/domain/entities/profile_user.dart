import '../../../auth/domain/entities/app_user.dart';
import 'package:json_annotation/json_annotation.dart';

part 'profile_user.g.dart';

@JsonSerializable()
class ProfileUserEntity extends AppUser {
  @JsonKey(defaultValue: '')
  final String bio;
  @JsonKey(defaultValue: '')
  final String profileImgUrl;
  @JsonKey(defaultValue: <String>[])
  final List<String> followers;
  @JsonKey(defaultValue: <String>[])
  final List<String> followings;
  @JsonKey(defaultValue: 0)
  final int? lastEmailUpdate;

  ProfileUserEntity({
    this.lastEmailUpdate,
    required this.followers,
    required this.followings,
    required this.bio,
    required this.profileImgUrl,
    required super.uid,
    required super.name,
    required super.email,
  });

  ProfileUserEntity copyWith({
    List<String>? newFollowers,
    List<String>? newFollowings,
    String? newBio,
    String? newProfileImgUrl,
    String? newEmail, // ✅ Add email parameter
    int? newLastEmailUpdate, // ✅ Add lastEmailUpdate parameter
  }) {
    return ProfileUserEntity(
      lastEmailUpdate: newLastEmailUpdate ?? lastEmailUpdate,
      bio: newBio ?? bio,
      profileImgUrl: newProfileImgUrl ?? profileImgUrl,
      uid: uid,
      name: name,
      email: newEmail ?? email, // ✅ Use newEmail parameter
      followers: newFollowers ?? followers,
      followings: newFollowings ?? followings,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$ProfileUserEntityToJson(this);

  factory ProfileUserEntity.fromJson(Map<String, dynamic> json) =>
      _$ProfileUserEntityFromJson(json);
}
