import 'package:ig_mate/features/auth/domain/entities/app_user.dart';

abstract class AuthRepo {
  Future<AppUser?> signInWithEmailAndPassword({String email, String password});
  Future<AppUser?> registerWithEmailAndPassword({
    String email,
    String password,
    String name,
  });
  Future<void> logout();
  Future<AppUser?> getCurrentUser();
}
