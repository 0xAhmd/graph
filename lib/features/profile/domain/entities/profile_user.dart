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
  @JsonKey(defaultValue: false)
  final bool isPrivate; // NEW FIELD

  ProfileUserEntity({
    required this.isPrivate, // NEW REQUIRED PARAMETER
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
    String? newEmail,
    int? newLastEmailUpdate,
    bool? newIsPrivate, // NEW PARAMETER
  }) {
    return ProfileUserEntity(
      lastEmailUpdate: newLastEmailUpdate ?? lastEmailUpdate,
      bio: newBio ?? bio,
      profileImgUrl: newProfileImgUrl ?? profileImgUrl,
      uid: uid,
      name: name,
      email: newEmail ?? email,
      followers: newFollowers ?? followers,
      followings: newFollowings ?? followings,
      isPrivate: newIsPrivate ?? isPrivate, // NEW FIELD
    );
  }

  @override
  Map<String, dynamic> toJson() => _$ProfileUserEntityToJson(this);

  factory ProfileUserEntity.fromJson(Map<String, dynamic> json) =>
      _$ProfileUserEntityFromJson(json);
}
