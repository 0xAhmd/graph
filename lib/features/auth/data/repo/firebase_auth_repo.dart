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
    } on FirebaseAuthException catch (e) {
      // convert Firebase error code to user-friendly message and throw it
      throw _mapFirebaseAuthErrorToMessage(e);
    } catch (e) {
      throw "Something went wrong. Please try again.";
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
    } on FirebaseAuthException catch (e) {
      // 👇 convert Firebase code into user-friendly message
      throw _mapFirebaseAuthErrorToMessage(e);
    } catch (e) {
      throw "Something went wrong. Please try again.";
    }
  }

  String _mapFirebaseAuthErrorToMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "No user found for that email.";
      case 'wrong-password':
        return "Incorrect password. Please try again.";
      case 'invalid-email':
        return "The email address is badly formatted.";
      case 'user-disabled':
        return "This user account has been disabled.";
      case 'too-many-requests':
        return "Too many login attempts. Try again later.";
      default:
        return "Login failed. Please try again.";
    }
  }
}
