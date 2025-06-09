import 'package:ig_mate/features/auth/domain/entities/app_user.dart';
import 'package:json_annotation/json_annotation.dart';

part 'profile_user.g.dart';

@JsonSerializable()
class ProfileUserEntity extends AppUser {
  @JsonKey(defaultValue: '')
  final String bio;
  @JsonKey(defaultValue: '')
  final String profileImgUrl;
  ProfileUserEntity({
    required this.bio,
    required this.profileImgUrl,
    required super.uid,
    required super.name,
    required super.email,
  });

  ProfileUserEntity copyWith({String? newBio, String? newProfileImgUrl}) {
    return ProfileUserEntity(
      bio: newBio ?? bio,
      profileImgUrl: newProfileImgUrl ?? profileImgUrl,
      uid: uid,
      name: name,
      email: email,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$ProfileUserEntityToJson(this);

  factory ProfileUserEntity.fromJson(Map<String, dynamic> json) =>
      _$ProfileUserEntityFromJson(json);
}
