import '../entities/app_user.dart';

abstract class AuthRepoContract {
  Future<AppUser?> signInWithEmailAndPassword({String email, String password});
  Future<AppUser?> registerWithEmailAndPassword({
    String email,
    String password,
    String name,
  });
  Future<void> logout();
  Future<AppUser?> getCurrentUser();

  Future<void> deleteAccount();

  Future<void> deleteUserInfoFromFirebase(String uid);
  Future<AppUser?> signInWithGoogle();
  Future<AppUser?> signInWithGitHub();
}
