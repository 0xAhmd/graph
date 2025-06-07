import 'package:firebase_auth/firebase_auth.dart';
import 'package:ig_mate/features/auth/domain/entities/app_user.dart';
import 'package:ig_mate/features/auth/domain/repo/auth_repo.dart';

class FirebaseAuthRepo implements AuthRepo {
  // get instance from firebase auth

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    return AppUser(uid: firebaseUser.uid, name: '', email: firebaseUser.email!);
  }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<AppUser?> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      // create the user
      AppUser user = AppUser(
        uid: userCredential.user!.uid,
        name: name,
        email: email,
      );
      return user;
    } catch (e) {
      throw Exception('Login Failed$e');
    }
  }

  @override
  Future<AppUser?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      // create the user
      AppUser user = AppUser(
        uid: userCredential.user!.uid,
        name: '',
        email: email,
      );
      return user;
    } catch (e) {
      throw Exception('Login Failed$e');
    }
  }
}
