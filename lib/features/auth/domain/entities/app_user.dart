import 'package:json_annotation/json_annotation.dart';

part 'app_user.g.dart';

@JsonSerializable()
class AppUser {
  // what user should have ?
  // 1. uid
  // 2. username
  // 3. name
  // 4. email

  final String uid;
  final String name;
  final String email;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);

  Map<String, dynamic> toJson() => _$AppUserToJson(this);
  // from and to json methods via json serializable
}
